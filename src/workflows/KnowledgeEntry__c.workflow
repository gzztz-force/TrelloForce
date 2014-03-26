<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Send_Email_on_new_knowledge_creation</fullName>
        <description>Send Email on new knowledge creation</description>
        <protected>false</protected>
        <recipients>
            <recipient>CEO</recipient>
            <type>role</type>
        </recipients>
        <recipients>
            <recipient>Developer</recipient>
            <type>role</type>
        </recipients>
        <recipients>
            <recipient>TeamManager</recipient>
            <type>role</type>
        </recipients>
        <recipients>
            <recipient>Tester</recipient>
            <type>role</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/New_Knowledge_Article</template>
    </alerts>
    <rules>
        <fullName>New Knowledge Article</fullName>
        <actions>
            <name>Send_Email_on_new_knowledge_creation</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>KnowledgeEntry__c.IsPublished__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
