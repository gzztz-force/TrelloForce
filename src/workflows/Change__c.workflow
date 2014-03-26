<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Send_Emails_on_new_Change</fullName>
        <description>Send Emails on new Change</description>
        <protected>false</protected>
        <recipients>
            <field>AssignedTo__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/ChangeAssignmentNotification</template>
    </alerts>
    <fieldUpdates>
        <fullName>Update_Change_Billable_to_False</fullName>
        <field>Billable__c</field>
        <literalValue>0</literalValue>
        <name>Update Change Billable to False</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>New Change Created</fullName>
        <actions>
            <name>Send_Emails_on_new_Change</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Change__c.AssignedTo__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Upate Change to Non-Billable</fullName>
        <actions>
            <name>Update_Change_Billable_to_False</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Set change to non-billable if customer name is Meginfo</description>
        <formula>Project__r.Customer__r.Name = &apos;Meginfo&apos;</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
