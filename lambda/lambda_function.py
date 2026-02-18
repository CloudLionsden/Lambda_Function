import boto3
import os
from datetime import datetime, timezone, timedelta

ec2 = boto3.client("ec2")

def lambda_handler(event, context):
    retention_days = int(os.environ.get("RETENTION_DAYS", "365"))
    cutoff_date = datetime.now(timezone.utc) - timedelta(days=retention_days)

    deleted_count = 0
    error_count = 0

    paginator = ec2.get_paginator("describe_snapshots")

    for page in paginator.paginate(OwnerIds=["self"]):
        for snapshot in page["Snapshots"]:
            snapshot_id = snapshot["SnapshotId"]
            start_time = snapshot["StartTime"]

            if start_time < cutoff_date:
                try:
                    print(f"Deleting snapshot: {snapshot_id} (Created: {start_time})")
                    ec2.delete_snapshot(SnapshotId=snapshot_id)
                    deleted_count += 1
                except Exception as e:
                    print(f"ERROR deleting snapshot {snapshot_id}: {str(e)}")
                    error_count += 1

    print(f"Cleanup complete. Deleted={deleted_count}, Errors={error_count}")

    return {
        "statusCode": 200,
        "deleted_snapshots": deleted_count,
        "errors": error_count
    }

