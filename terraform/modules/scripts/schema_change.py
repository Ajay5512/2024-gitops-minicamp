import sys

import boto3
import pandas as pd
from awsglue.utils import getResolvedOptions

# Get job parameters
args = getResolvedOptions(sys.argv, ["catalog_id", "db_name", "topic_arn"])


def get_tables_in_database():
    """Get all tables in the specified database"""
    glue = boto3.client("glue")
    try:
        response = glue.get_tables(
            CatalogId=args["catalog_id"], DatabaseName=args["db_name"]
        )
        return [table["Name"] for table in response.get("TableList", [])]
    except Exception as e:
        print(f"Error getting tables from database: {str(e)}")
        return []


def get_table_versions(table_name):
    glue = boto3.client("glue")
    try:
        response = glue.get_table_versions(
            CatalogId=args["catalog_id"],
            DatabaseName=args["db_name"],
            TableName=table_name,
            MaxResults=100,
        )

        if "TableVersions" not in response or len(response["TableVersions"]) < 2:
            print(f"Not enough versions to compare for table {table_name}")
            return None, None

        versions = sorted(
            response["TableVersions"], key=lambda x: int(x["VersionId"]), reverse=True
        )

        return versions[0], versions[1]  # Latest and previous versions
    except Exception as e:
        print(f"Error getting table versions for {table_name}: {str(e)}")
        return None, None


def compare_schemas(new_version, old_version):
    changes = []

    new_columns = pd.DataFrame(new_version["Table"]["StorageDescriptor"]["Columns"])
    old_columns = pd.DataFrame(old_version["Table"]["StorageDescriptor"]["Columns"])

    # Check for new or modified columns
    for _, new_col in new_columns.iterrows():
        old_col = old_columns[old_columns["Name"] == new_col["Name"]]
        if old_col.empty:
            changes.append(
                f"Added new column '{new_col['Name']}' with type '{new_col['Type']}'"
            )
        elif old_col.iloc[0]["Type"] != new_col["Type"]:
            changes.append(
                f"Changed type of column '{new_col['Name']}' from '{old_col.iloc[0]['Type']}' to '{new_col['Type']}'"
            )

    # Check for deleted columns
    for _, old_col in old_columns.iterrows():
        if old_col["Name"] not in new_columns["Name"].values:
            changes.append(f"Deleted column '{old_col['Name']}'")

    return changes


def notify_changes(changes, table_name):
    sns = boto3.client("sns")
    message = (
        f"Schema changes detected in {args['db_name']}.{table_name}:\n\n"
        f"The following changes were identified:\n"
    )

    for change in changes:
        message += f"- {change}\n"

    message += (
        "\nPlease review these changes and update any dependent processes if necessary."
    )

    try:
        sns.publish(
            TopicArn=args["topic_arn"],
            Message=message,
            Subject=f"Schema Changes Detected - {table_name}",
        )
        print(
            f"Notification sent to SNS topic: {args['topic_arn']} for table {table_name}"
        )
    except Exception as e:
        print(f"Error sending SNS notification: {str(e)}")


def main():
    print(f"Starting schema change detection for database {args['db_name']}")

    # Get all tables in the database
    tables = get_tables_in_database()
    if not tables:
        print(f"No tables found in database {args['db_name']}")
        return

    print(f"Found tables: {tables}")

    for table_name in tables:
        print(f"\nChecking schema changes for table: {table_name}")
        new_version, old_version = get_table_versions(table_name)
        if not new_version or not old_version:
            continue

        changes = compare_schemas(new_version, old_version)

        if changes:
            print(f"Detected {len(changes)} schema changes in {table_name}")
            notify_changes(changes, table_name)
        else:
            print(f"No schema changes detected for {table_name}")


if __name__ == "__main__":
    main()
