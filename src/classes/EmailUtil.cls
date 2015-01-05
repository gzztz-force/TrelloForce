/*
 * Send email util methods
 */
public class EmailUtil
{
    // Send a text body email to one recipient
    public static Boolean sendSampleEmail(String address, String subject, String body)
    {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setToAddresses(new String[] { address });
        mail.setSubject(subject);
        mail.setPlainTextBody(body);

        List<Messaging.SendEmailResult> emailResults = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

        return emailResults.get(0).isSuccess();
    }
}