<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_Time_Card_Billable_Field</fullName>
        <field>Billable__c</field>
        <literalValue>0</literalValue>
        <name>Update Time Card Billable Field</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Update Time Card Billable Field</fullName>
        <actions>
            <name>Update_Time_Card_Billable_Field</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>AND(IF(ISBLANK(Change__c), 
       IF(Project__r.Billable__c, false, true),
       IF(Change__r.CreatedDate &gt; DATETIMEVALUE(&quot;2014-1-25 00:00:00&quot;), 
          IF(Change__r.Billable__c, false, true),
          false
       )
   )
)</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
