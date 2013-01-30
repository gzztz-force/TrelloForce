<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>New_Site_Lead_Created_Email</fullName>
        <description>New Site Lead Created Email</description>
        <protected>false</protected>
        <recipients>
            <recipient>aaron.lau@pm.meginfo.com.dev</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>noam.haberfeld@pm.meginfo.com.dev</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/New_Site_Lead_Created_Template</template>
    </alerts>
    <rules>
        <fullName>New Site Lead</fullName>
        <actions>
            <name>New_Site_Lead_Created_Email</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead.Email</field>
            <operation>notEqual</operation>
            <value>null</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
