global class EmailToOwner  implements Database.Batchable<sObject>, Database.Stateful {
    
    Map<Id,String> ownerRecords = new Map<Id,String>();
    String excelHeader ='Id, Subject, Status, Priority, CaseNumber, Reason, Origin \n';
    String finalStr = excelHeader;
    String recString = '';
    String finalStrValue = '';
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id,Subject,Status,Priority,CaseNumber,Reason,Origin,OwnerID FROM case';
        //String query = System.Label.caseQuery;
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<Case> casesList) {
        for(Case c : casesList)
        {
            String recordString = c.Id+',"'+c.Subject+'",'+c.Status+','+c.Priority+','+c.CaseNumber+','+c.Reason+','+c.Origin+'\n';
            //String recordString = System.Label.recordString;
            if(ownerRecords.containsKey(c.ownerID)){
                recString = ownerRecords.get(c.ownerID) + recordString;
                ownerRecords.put(c.ownerID,recString);
                
            }else{
                finalStrValue = excelHeader+recordString;
                ownerRecords.put(c.ownerID,finalStrValue);
            }
        }
    }   
    
    global void finish(Database.BatchableContext bc) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        
        for(ID caseOwnerId : ownerRecords.keySet()){
            
            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
            blob excel = blob.valueOf(ownerRecords.get(caseOwnerId));
            attach.setBody(excel);
            attach.setFileName('ExcelfileCaseRecords.xls');
            
            string subject = 'Case Record Details';
            string body = 'This file is generated using send email to owner';
            
            Messaging.singleEmailMessage Emailwithattch = new Messaging.singleEmailMessage();
            Emailwithattch.setSubject(subject);
            Emailwithattch.setTargetObjectId(caseOwnerId);
            Emailwithattch.setSaveAsActivity(false);  
            Emailwithattch.setPlainTextBody(body);
            Emailwithattch.setFileAttachments(new Messaging.EmailFileAttachment[]{attach});
            mails.add(Emailwithattch);
        }
        
        try {
            Messaging.sendEmail(mails);
            
        } catch(Exception e) {
            System.debug(e);
        } 
    }
}