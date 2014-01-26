/*
 ** This class is called by the schedule named "TimeCardScheduler" on daily basis,
 ** which will get all the un-synced time entries for Touchpoint and import them to Touchpoint org.

 ** Created by Eric on 2014/1/3.
 */
public class TimeCardSyncService 
{
	private static String managerName = 'Eric He';
	private static String managerEmail = 'eric.he@meginfo.com';
	private static String endpoint = 'https://inlab-developer-edition.ap1.force.com/services/apexrest/TimeCardManagment/';
	private static String salesforceBaseUrl;

	private static Map<String, List<TimeCard__c>> timeCardOwner2TimeCards = new Map<String, List<TimeCard__c>>(); 
	private static Map<String, List<change__c>> changeOwner2Changes = new Map<String, List<Change__c>>();
	private static List<TimeCard__c> validTimeEntries = new List<TimeCard__c>();
	
	// To make callout from schedule job, we need annotate the static method with future.
	@future (callout=true)
	public static void invokeTimeCardSync()
	{		
		// Gets the manager name and email from cutom settings to set the
		// managerName and managerEmail variables.
		getConfigFromCustomSettings();
		// Gets Salesforce Base Url.
		salesforceBaseUrl = URL.getSalesforceBaseUrl().toExternalForm();		

		for(TimeCard__c entry : [select Id, Name, IsSync__c, Billable__c, Date__c, Hours__c, Description__c, Project__c, Change__c,
										Project__r.Name, TeamMember__r.User__r.Name, TeamMember__r.User__r.Email, 
										Change__r.Name, Change__r.ExternalID__c, Change__r.Project__c, Change__r.Project__r.Name, Change__r.CreatedBy.Name, Change__r.CreatedBy.Email
								from TimeCard__c where IsSync__c = false and Project__r.Customer__r.Name = 'Touchpoint' 
								order by Project__r.Name, Change__r.Name, Name])
		{
			// The Change__c field value must be set, because it's
			// required in Touchpoint's system.
			if(String.isBlank(entry.Change__c))
			{
				if(!timeCardOwner2TimeCards.containsKey(entry.TeamMember__r.User__r.Name))
				{
					timeCardOwner2TimeCards.put(entry.TeamMember__r.User__r.Name, new List<TimeCard__c>());
				}
				timeCardOwner2TimeCards.get(entry.TeamMember__r.User__r.Name).add(entry);
			}
			// If the ExternalID__c is not set, there is no way to
			// find the related Requirement__c id in Touchpoint's system.
			else if(String.isBlank(entry.Change__r.ExternalID__c))
			{
				if(!changeOwner2Changes.containsKey(entry.Change__r.CreatedBy.Name))
				{
					changeOwner2Changes.put(entry.Change__r.CreatedBy.Name, new List<Change__c>());
				}
				changeOwner2Changes.get(entry.Change__r.CreatedBy.Name).add(entry.Change__r);
			}
			else
			{
				validTimeEntries.add(entry);
			}
		}	
		
		if(validTimeEntries.size() > 0)
		{
			importTimeCards();
		}
		if(timeCardOwner2TimeCards.size() > 0)
		{
			notifyTimeCardOwner();
		}					
		if(changeOwner2Changes.size() > 0)
		{
			notifyChangeOwner();
		}				
	}	
	private static void getConfigFromCustomSettings()
	{
		List<TimeCardSyncSetting__c> settings = TimeCardSyncSetting__c.getAll().values();
		if(!settings.isEmpty())
		{
			managerName = settings[0].Name;
			managerEmail = settings[0].Email__c;
			endpoint = settings[0].Endpoint__c;
		}
	}
	private static void importTimeCards()
	{
		if(Test.isRunningTest())
		{
			Map<String, String> timeCardId2ErrorMsg = new Map<String, String>{validTimeEntries[0].Id => 'Unknown Exception'};
			generateJSONString();
			handlePostResponse(timeCardId2ErrorMsg);
		}
		else
		{
			HttpRequest request = new HttpRequest();
			request.setEndpoint(endpoint);
			request.setMethod('POST');
			request.setHeader('Content-Type', 'application/json;charset=UTF-8');
			request.setBody(generateJSONString());		
			Http http = new Http();
			HttpResponse response = http.send(request);
			Map<String, String> timeCardId2ErrorMsg = (Map<String, String>)JSON.deserialize(response.getBody(), Map<String, String>.class);
			// For those TimeCard__c records which have been synced correctly, update their IsSync__c to true.
			// For th failed records, notify the TimeCard owner to correct them. 
			handlePostResponse(timeCardId2ErrorMsg);
		}		
	}
	private static String generateJSONString()
	{
		JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartObject();
		gen.writeStringField('teamMember', managerName);
		gen.writeFieldName('timeCards');
		gen.writeStartArray();
		for(TimeCard__c timeCard : validTimeEntries)
		{
			gen.writeStartObject();
			gen.writeStringField('TimeCardId', timeCard.Id);
			gen.writeFieldName('TimeEntry');
			gen.writeStartObject();
			gen.writeStringField('Requirement__c', timeCard.Change__r.ExternalID__c);
			gen.writeDateField('Date__c', timeCard.Date__c);
			gen.writeNumberField('Hours__c', timeCard.Hours__c);
			gen.writeStringField('Description__c', timeCard.Description__c);
			gen.writeStringField('Type__c', (timeCard.Billable__c ? 'Billable' : 'Non-Billable'));
			gen.writeEndObject();
			gen.writeEndObject();
		}
		gen.writeEndArray();
		gen.writeEndObject();	
		return gen.getAsString();
	}

	private static void handlePostResponse(Map<String, String> timeCardId2ErrorMsg)
	{
		if(timeCardId2ErrorMsg.isEmpty())
		{
			checkIsSyncForTimeCards(validTimeEntries);
		}
		else
		{
			notifyTimeCardOwner(timeCardId2ErrorMsg);

			Map<String, TimeCard__c> validTimeEntryMap = new Map<String, TimeCard__c>();
			for(TimeCard__c entry : validTimeEntries)
			{
				validTimeEntryMap.put(entry.Id, entry);
			}		
			for(String timeCardId : timeCardId2ErrorMsg.keySet())
			{
				validTimeEntryMap.remove(timeCardId);
			}
			if(!validTimeEntryMap.isEmpty())
			{
				checkIsSyncForTimeCards(validTimeEntryMap.values());
			}
		}

	}
	// Sets IsSync__c to true after the TimeCard__c records are imported to our client's system.
	private static void checkIsSyncForTimeCards(List<TimeCard__c> importedTimeCards)
	{
		for(TimeCard__c entry : importedTimeCards)
		{
			entry.IsSync__c = true;
		}
		update importedTimeCards;
	}
	// Sends emails to the time card owners to ask them to figure out the reason why
	// some of their TimeCard records failed to be synced, altough the Change and ExternalID
	// fields value have been specified.
	private static void notifyTimeCardOwner(Map<String, String> timeCardId2ErrorMsg)
	{
		Map<String, List<TimeCard__c>> timeCardMap = new Map<String, List<TimeCard__c>>();
		for(TimeCard__c entry : [select Id, Name, Project__c, Project__r.Name, Change__c, Change__r.Name, Change__r.ExternalID__c, TeamMember__r.User__r.Name, TeamMember__r.User__r.Email from TimeCard__c where Id in :timeCardId2ErrorMsg.keySet()])
		{
			if(!timeCardMap.containsKey(entry.TeamMember__r.User__r.Name))
			{
				timeCardMap.put(entry.TeamMember__r.User__r.Name, new List<TimeCard__c>());
			}
			timeCardMap.get(entry.TeamMember__r.User__r.Name).add(entry);			
		}		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setSubject('Time Card Sync Exception - ' + Date.today().format());		
		Set<String> timeCardOwnerEmails = new Set<String>();	
		/*	
		for(String timeCardOwner : timeCardOwner2TimeCards.keySet())
		{
			timeCardOwnerEmails.add(timeCardOwner2TimeCards.get(timeCardOwner).get(0).TeamMember__r.User__r.Email);
		}
		*/		
		// The email set in the custom settings must be added to get the notification.
		timeCardOwnerEmails.add(managerEmail);
		mail.setToAddresses(new List<String>(timeCardOwnerEmails));
		// Ordrs the TimeCard records by TimeCard Owner name.
		List<String> timeCardOwners = new List<String>(timeCardMap.keySet());
		timeCardOwners.sort();
		String summary = 'You are getting this email because some of your TimeCard records falied to be synced to our client\'s system, please correct your TimeCard records or contact your manager to get this fixed ASAP.';
		String htmlBody = '<div style="background: #ddd; margin-top: 20px;">';
		htmlBody += '<div style="width: 90%; margin: auto; background: #FFF; border: 1px solid #ddd">';
		htmlBody += '<div style="background: #F2F2F2; padding: 30px 40px; font-size: 14px; color: #cc762b; font-weight: bold;">' + summary + '</div>';		
		for(String timeCardOwner : timeCardOwners)
		{
			htmlBody += '<div style="margin: 20px 40px; border: 1px solid #ddd; border-radius: 4px;">';
			htmlBody += '<div style="color: #0084b4; font-size: 14px; font-weight: bold; padding: 20px 10px;">' + timeCardOwner + '</div>';
			htmlBody += '<table width="100%" cellspacing="0" cellpadding="10">';
			htmlBody += '<tr>' + 						
							'<th style="border-top: 1px solid #ddd; text-align: left;">Project</th>' +
							'<th style="border-top: 1px solid #ddd; text-align: left;">Change</th>' +
							'<th style="border-top: 1px solid #ddd; text-align: left;">ExternalID</th>' +
							'<th style="border-top: 1px solid #ddd; text-align: left;">Time Card</th>' +
							'<th style="border-top: 1px solid #ddd; text-align: left;">Error Message</th>' +
						'</tr>';
			for(TimeCard__c entry : timeCardMap.get(timeCardOwner))
			{
				htmlBody += '<tr>' + 
								'<td style="border-top: 1px solid #ddd;"><a href="' + salesforceBaseUrl + '/' + entry.Project__c + '">' + entry.Project__r.Name + '</a></td>' +
								'<td style="border-top: 1px solid #ddd;"><a href="' + salesforceBaseUrl + '/' + entry.Change__c + '">' + entry.Change__r.Name + '</a></td>' +
								'<td style="border-top: 1px solid #ddd;">' + entry.Change__r.ExternalID__c + '</td>' +								
								'<td style="border-top: 1px solid #ddd;"><a href="' + salesforceBaseUrl + '/' + entry.Id + '">' + entry.Name + '</a></td>' +
								'<td style="border-top: 1px solid #ddd;">' + timeCardId2ErrorMsg.get(entry.Id) + '</td>' +
							'</tr>';
			}					
			htmlBody += '</table>';
			htmlBody += '</div>';
		}				
		htmlBody += '</div>';
		htmlBody += '</div>';
		mail.setHtmlBody(htmlBody);
		Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
	}
	// Sends emails to the time card owners to ask them to specify a value for Change field on TimeCard object.
	private static void notifyTimeCardOwner()
	{
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setSubject('Time Card Sync Exception: No Change Specified - ' + Date.today().format());		
		Set<String> timeCardOwnerEmails = new Set<String>();	
		/*	
		for(String timeCardOwner : timeCardOwner2TimeCards.keySet())
		{
			timeCardOwnerEmails.add(timeCardOwner2TimeCards.get(timeCardOwner).get(0).TeamMember__r.User__r.Email);
		}
		*/		
		// The email set in the custom settings must be added to get the notification.
		timeCardOwnerEmails.add(managerEmail);
		mail.setToAddresses(new List<String>(timeCardOwnerEmails));
		// Ordrs the TimeCard records by TimeCard Owner name.
		List<String> timeCardOwners = new List<String>(timeCardOwner2TimeCards.keySet());
		timeCardOwners.sort();
		String summary = 'You are getting this email because some of your TimeCard records are not having Change field populated, the Change field must be specified to get our TimeCard records synced to our client\'s system.';
		String htmlBody = '<div style="background: #ddd; margin-top: 20px;">';
		htmlBody += '<div style="width: 90%; margin: auto; background: #FFF; border: 1px solid #ddd">';
		htmlBody += '<div style="background: #F2F2F2; padding: 30px 40px; font-size: 14px; color: #cc762b; font-weight: bold;">' + summary + '</div>';		
		for(String timeCardOwner : timeCardOwners)
		{
			htmlBody += '<div style="margin: 20px 40px; border: 1px solid #ddd; border-radius: 4px;">';
			htmlBody += '<div style="color: #0084b4; font-size: 14px; font-weight: bold; padding: 20px 10px;">' + timeCardOwner + '</div>';
			htmlBody += '<table width="100%" cellspacing="0" cellpadding="10">';
			htmlBody += '<tr>' + 						
							'<th style="border-top: 1px solid #ddd; text-align: left; width: 60%">Project</th>' +
							'<th style="border-top: 1px solid #ddd; text-align: left;">Time Card</th>' +
						'</tr>';
			for(TimeCard__c entry : timeCardOwner2TimeCards.get(timeCardOwner))
			{
				htmlBody += '<tr>' + 
								'<td style="border-top: 1px solid #ddd;"><a href="' + salesforceBaseUrl + '/' + entry.Project__c + '">' + entry.Project__r.Name + '</a></td>' +
								'<td style="border-top: 1px solid #ddd;"><a href="' + salesforceBaseUrl + '/' + entry.Id + '">' + entry.Name + '</a></td>' +
							'</tr>';
			}					
			htmlBody += '</table>';
			htmlBody += '</div>';
		}				
		htmlBody += '</div>';
		htmlBody += '</div>';
		mail.setHtmlBody(htmlBody);
		Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
	}
	// // Sends emails to the change owners to ask them to specify a value for ExternalID field on Change object.
	private static void notifyChangeOwner()
	{
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setSubject('Time Card Sync Exception: No ExternalID Specified - ' + Date.today().format());		
		Set<String> changeOwnerEmails = new Set<String>();	
		/*
		for(String changeOwner : changeOwner2Changes.keySet())
		{
			changeOwnerEmails.add(changeOwner2Changes.get(changeOwner).get(0).CreatedBy.Email);
		}
		*/
		// The email set in the custom settings must be added to get the notification.
		changeOwnerEmails.add(managerEmail);
		mail.setToAddresses(new List<String>(changeOwnerEmails));
		// Ordrs the Change records by Change Owner name.
		List<String> changeOwners = new List<String>(changeOwner2Changes.keySet());
		changeOwners.sort();
		String summary = 'You are getting this email because some of Change records you created are not having ExternalID field populated, the ExternalID field must be specified to get our TimeCard records synced to our client\'s system.';
		String htmlBody = '<div style="background: #ddd; margin-top: 20px;">';
		htmlBody += '<div style="width: 90%; margin: auto; background: #FFF; border: 1px solid #ddd">';
		htmlBody += '<div style="background: #F2F2F2; padding: 30px 40px; font-size: 14px; color: #cc762b; font-weight: bold;">' + summary + '</div>';		
		for(String changeOwner : changeOwners)
		{
			htmlBody += '<div style="margin: 20px 40px; border: 1px solid #ddd; border-radius: 4px;">';
			htmlBody += '<div style="color: #0084b4; font-size: 14px; font-weight: bold; padding: 20px 10px;">' + changeOwner + '</div>';
			htmlBody += '<table width="100%" cellspacing="0" cellpadding="10">';
			htmlBody += '<tr>' + 						
							'<th style="border-top: 1px solid #ddd; text-align: left; width: 40%">Project</th>' +
							'<th style="border-top: 1px solid #ddd; text-align: left;">Change</th>' +
						'</tr>';
			for(Change__c change : changeOwner2Changes.get(changeOwner))
			{
				htmlBody += '<tr>' + 
								'<td style="border-top: 1px solid #ddd;"><a href="' + salesforceBaseUrl + '/' + change.Project__c + '">' + change.Project__r.Name + '</a></td>' +
								'<td style="border-top: 1px solid #ddd;"><a href="' + salesforceBaseUrl + '/' + change.Id + '">' + change.Name + '</a></td>' +
							'</tr>';
			}					
			htmlBody += '</table>';
			htmlBody += '</div>';
		}				
		htmlBody += '</div>';
		htmlBody += '</div>';
		mail.setHtmlBody(htmlBody);
		Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
	}
}