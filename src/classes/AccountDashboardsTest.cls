/*
Copyright (c) 2011 salesforce.com, inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. The name of the author may not be used to endorse or promote products
   derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

By: Chris Kemp <ckemp@salesforce.com>
*/

public class AccountDashboardsTest {

    static Account makeNewAccount() {
        Account newAcct = new Account();
        newAcct.Name = 'Test Account';
        insert newAcct;
        return newAcct;
    }

    static testMethod void testClosedSalesAmountYoY() {
        Account newAcct = makeNewAccount();
        
        AccountDashboardsController adc = new AccountDashboardsController(newAcct);
        String beforeString = adc.getClosedSalesAmountYoY();
        
        // Add new oppty - this should change the graph
        Opportunity newOppty = new Opportunity();
        newOppty.Name = 'Test Oppty #1';
        newOppty.AccountId = newAcct.Id;
        newOppty.CloseDate = Date.today();
        newOppty.Amount = 11111;
        newOppty.StageName = [SELECT MasterLabel FROM OpportunityStage WHERE IsWon = TRUE AND IsActive = TRUE LIMIT 1].MasterLabel;
        insert newOppty;

        String afterString = adc.getClosedSalesAmountYoY();
        System.assert(!(beforeString.equals(afterString)));
    }

    static testMethod void testClosedSalesAmountMoM() {
        Account newAcct = makeNewAccount();
        
        AccountDashboardsController adc = new AccountDashboardsController(newAcct);
        String beforeString = adc.getClosedSalesAmountMoM();
        
        // Add new oppty - this should change the graph
        Opportunity newOppty = new Opportunity();
        newOppty.Name = 'Test Oppty #2';
        newOppty.AccountId = newAcct.Id;
        newOppty.CloseDate = Date.today();
        newOppty.Amount = 22222;
        newOppty.StageName = [SELECT MasterLabel FROM OpportunityStage WHERE IsWon = TRUE AND IsActive = TRUE LIMIT 1].MasterLabel;
        insert newOppty;

        String afterString = adc.getClosedSalesAmountMoM();
        System.assert(!(beforeString.equals(afterString)));
    }

    static testMethod void testProductGraphs() {
        Account newAcct = makeNewAccount();
        
        AccountDashboardsController adc = new AccountDashboardsController(newAcct);
        String beforeAmtString = adc.getSalesAmountByProduct();
        String beforeQtyString = adc.getSalesQuantityByProduct();
        
        // Add new oppty - this should change the graph
        Opportunity newOppty = new Opportunity();
        newOppty.Name = 'Test Oppty #3';
        newOppty.AccountId = newAcct.Id;
        newOppty.CloseDate = Date.today();
        newOppty.Amount = 33333;
        newOppty.StageName = [SELECT MasterLabel FROM OpportunityStage WHERE IsWon = TRUE AND IsActive = TRUE LIMIT 1].MasterLabel;
        insert newOppty;

        // Create test product to add to oppty later
        Product2 newProduct = new Product2();
        newProduct.Name = 'Test Widget';
        newProduct.Family = 'Widgets';
        insert newProduct;

        // Create a pricebook
        //Pricebook2 pb = new Pricebook2();
        //pb.Name = 'Custom Pricebok';
        //pb.IsActive = TRUE;
        //insert pb;
        
        // Create pricebook entry
        PricebookEntry pbe = new PricebookEntry();
        pbe.IsActive = TRUE;
        pbe.Pricebook2Id = [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1].Id;
        pbe.Product2Id = newProduct.Id;
        pbe.UnitPrice = 5555;
        pbe.UseStandardPrice = FALSE;
        insert pbe;
        
        // Add product to oppty
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = newOppty.Id;
        oli.PricebookEntryId = pbe.Id;
        oli.Quantity = 5;
        oli.TotalPrice = 5 * 5555;
        insert oli;

        String afterAmtString = adc.getSalesAmountByProduct();
        System.assert(!(beforeAmtString.equals(afterAmtString)));

        String afterQtyString = adc.getSalesQuantityByProduct();
        System.assert(!(beforeQtyString.equals(afterQtyString)));
    }    

}