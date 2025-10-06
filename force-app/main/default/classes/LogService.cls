public class LogService {

    public static void logError(Exception ex, String userFriendlyMessage, String className) {
        try {
            Log__c logEntry = new Log__c();
            logEntry.Message__c = ex.getMessage();
            logEntry.StackTrace__c = ex.getStackTraceString();
            logEntry.User_Friendly_Message__c = userFriendlyMessage;
            logEntry.Class_Name__c = className;
            insert logEntry;
        } catch (Exception loggingEx) {
            System.debug('Logging failed: ' + loggingEx.getMessage());
        }
    }
}