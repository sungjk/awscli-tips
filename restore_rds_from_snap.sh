#!/bin/bash

NOW_DATE=$(date '+%Y-%m-%d-%H-%M')
RESTORE_FROM_INSTANCE_ID=<source name>
TARGET_INSTANCE_ID=<target name>
TARGET_INSTANCE_CLASS=db.m4.large
VPC_ID=<vpc subnet id>
NEW_MASTER_PASS=<root password>
SECURITY_GROUP_ID=<target security group id>

echo "+------------------------------------------------------------------------------------+"
echo "| Restore RDS Instance from Snapshot                                                 |"
echo "+------------------------------------------------------------------------------------+"
echo ""

echo "Creating manual snapshot of ${RESTORE_FROM_INSTANCE_ID}"
SNAPSHOT_ID=$(aws rds create-db-snapshot --db-snapshot-identifier $RESTORE_FROM_INSTANCE_ID-manual-$NOW_DATE --db-instance-identifier $RESTORE_FROM_INSTANCE_ID --query 'DBSnapshot.[DBSnapshotIdentifier]' --output text)
aws rds wait db-snapshot-completed --db-snapshot-identifier $SNAPSHOT_ID
echo "Finished creating new snapshot ${SNAPSHOT_ID} from ${RESTORE_FROM_INSTANCE_ID}"

echo "Checking for an existing instance with the identifier ${TARGET_INSTANCE_ID}"
EXISTING_INSTANCE=$(aws rds describe-db-instances --db-instance-identifier $TARGET_INSTANCE_ID --query 'DBInstances[0].[DBInstanceIdentifier]' --output text)

if [ "${EXISTING_INSTANCE}" == "${TARGET_INSTANCE_ID}" ];
then
    if [ "${TARGET_INSTANCE_ID}" == "${RESTORE_FROM_INSTANCE_ID}" ];
    then
        echo "Miss matched instance id."
        exit 1;
    fi
    echo "Deleting existing instance found with identifier ${TARGET_INSTANCE_ID}"
    aws rds delete-db-instance --db-instance-identifier $TARGET_INSTANCE_ID --skip-final-snapshot
    aws rds wait db-instance-deleted --db-instance-identifier $TARGET_INSTANCE_ID
    echo "Finished deleting ${TARGET_INSTANCE_ID}"
fi

# echo "Finding latest snapshot for ${SNAPSHOT_TARGET_INSTANCE_ID}"
# SNAPSHOT_ID=$(aws rds describe-db-snapshots --db-instance-identifier $RESTORE_FROM_INSTANCE_ID --query 'DBSnapshots[-1].[DBSnapshotIdentifier]' --output text)
# echo "Snapshot found: ${SNAPSHOT_ID}"

echo "Restoring snapshot ${SNAPSHOT_ID} to a new db instance ${TARGET_INSTANCE_ID}..."
aws rds restore-db-instance-from-db-snapshot \
    --db-instance-identifier $TARGET_INSTANCE_ID \
    --db-snapshot-identifier $SNAPSHOT_ID \
    --db-instance-class $TARGET_INSTANCE_CLASS \
    --db-subnet-group-name $VPC_ID \
    --no-multi-az \
    --publicly-accessible


while [ "${exit_status}" != "0" ]
do
    echo "Waiting for ${TARGET_INSTANCE_ID} to enter 'available' state..."
    aws rds wait db-instance-available --db-instance-identifier $TARGET_INSTANCE_ID
    exit_status="$?"

    INSTANCE_STATUS=$( aws rds describe-db-instances --db-instance-identifier $TARGET_INSTANCE_ID --query 'DBInstances[0].[DBInstanceStatus]' --output text )
    echo "${TARGET_INSTANCE_ID} instance state is: ${INSTANCE_STATUS}"
done
echo "Finished creating instance ${TARGET_INSTANCE_ID} from snapshot ${SNAPSHOT_ID}"

echo "Updating instance ${TARGET_INSTANCE_ID} backup retention period to 0"
aws rds modify-db-instance \
    --db-instance-identifier $TARGET_INSTANCE_ID \
    --vpc-security-group-ids $SECURITY_GROUP_ID \
    --backup-retention-period 0 \
    --apply-immediately

aws rds wait db-instance-available --db-instance-identifier $TARGET_INSTANCE_ID
echo "Finished updating ${TARGET_INSTANCE_ID}"

echo "SUCCESS: Operation complete. Created instance ${TARGET_INSTANCE_ID} from snapshot ${SNAPSHOT_ID}"

exit 0
