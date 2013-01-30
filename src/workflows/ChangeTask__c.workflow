<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Send_Emails_on_new_Change_Task</fullName>
        <description>Send Emails on new Change Task</description>
        <protected>false</protected>
        <recipients>
            <field>AssignedTo__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/ChangeTaskAssignmentNotification</template>
    </alerts>
    <rules>
        <fullName>New Change Task Notification</fullName>
        <actions>
            <name>Send_Emails_on_new_Change_Task</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>ChangeTask__c.AssignedTo__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
