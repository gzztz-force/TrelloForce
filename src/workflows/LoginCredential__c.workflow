<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Send_Email_On_SCM_Error</fullName>
        <description>Send Email On SCM Error</description>
        <protected>false</protected>
        <recipients>
            <recipient>jair.zheng@pm.meginfo.com</recipient>
            <type>user</type>
        </recipients>
        <senderAddress>pm@meginfo.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/SCM_Error_Notification</template>
    </alerts>
    <rules>
        <fullName>SCM Error Notification</fullName>
        <actions>
            <name>Send_Email_On_SCM_Error</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>NOT(ISBLANK( SyncError__c )) &amp;&amp; ISCHANGED( SyncError__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
