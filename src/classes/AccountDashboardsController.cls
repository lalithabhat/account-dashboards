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
/** Test Change **/
public with sharing class AccountDashboardsController {

    private final Account acct;
    
    // Default number of years shown on the "Account Sales, Year over Year" report
    static final Integer CLOSED_SALES_AMOUNT_YOY_YEARS_SHOWN = 5;
    
    // Default number of years shown on the "Account Sales, Month over Month" report
    static final Integer CLOSED_SALES_AMOUNT_MOM_YEARS_SHOWN = 3;

    
    public AccountDashboardsController(ApexPages.StandardController stdController) {
        this.acct = (Account)stdController.getRecord();
    }

    // For test methods
    public AccountDashboardsController(Account acct) {
        this.acct = acct;
    }

    // Controller to generate the data for the "Account Sales, Year over Year" chart
    public String getClosedSalesAmountYoY() {
        String id = this.acct.Id; 
        final Integer firstYear = date.today().year() - CLOSED_SALES_AMOUNT_YOY_YEARS_SHOWN + 1;
    
        AggregateResult[] groupedResults = [SELECT FISCAL_YEAR(CloseDate) YearOfSale,    
            SUM(Amount) TotalAmount FROM Opportunity 
            WHERE AccountId = :id AND FISCAL_YEAR(CloseDate) >= :firstYear AND IsWon = TRUE
            GROUP BY FISCAL_YEAR(CloseDate) ORDER BY FISCAL_YEAR(CloseDate) ASC];

        Integer dataCount = 0;
        Integer resultCount = 0;
        String resultJS = 'data.addRows(' + CLOSED_SALES_AMOUNT_YOY_YEARS_SHOWN + ');\n';
        
        Map<String, Double> resultMap = new Map<String, Double>();
        for (AggregateResult ar : groupedResults)  {
            resultMap.put(String.valueOf(ar.get('YearOfSale')), (Double)ar.get('TotalAmount'));
        }
  
        // We need to do this so we can fill in blank values with a zero and restrict to the
        // number of years specified in the constant CLOSED_SALES_AMOUNT_YOY_YEARS_SHOWN
        Integer count = 0;
        Integer currentYear = firstYear;

        while (currentYear <= date.today().year()) {
            resultJS += 'data.setValue(' + count + ', 0, \'' +   String.valueOf(currentYear) + '\');\n';
        
            if (resultMap.get(String.valueOf(currentYear)) != null) {
                resultJS += 'data.setValue(' + count + ', 1, ' +  
                    resultMap.get(String.valueOf(currentYear)) + ');\n';

            } else {
                resultJS += 'data.setValue(' + count + ', 1, 0);\n';
            }

            count++;
            currentYear++;
        }
        return resultJS;
    }


    // Controller to generate the data for the "Account Sales, Month over Month" chart
    public String getClosedSalesAmountMoM() {
        String id = this.acct.Id;
        final Integer firstYear = date.today().year() - CLOSED_SALES_AMOUNT_MOM_YEARS_SHOWN + 1;
    
        AggregateResult[] groupedResults = [SELECT FISCAL_MONTH(CloseDate) MonthOfSale,
            FISCAL_YEAR(CloseDate) YearOfSale,    
            SUM(Amount) TotalAmount FROM Opportunity 
            WHERE AccountId = :id AND FISCAL_YEAR(CloseDate) >= :firstYear AND IsWon = TRUE
            GROUP BY FISCAL_MONTH(CloseDate), FISCAL_YEAR(CloseDate) 
            ORDER BY FISCAL_MONTH(CloseDate), FISCAL_YEAR(CloseDate)];

        Integer dataCount = 0;
        Integer resultCount = 0;
        
        Map<String, Double> resultMap = new Map<String, Double>();
        for (AggregateResult ar : groupedResults)  {

            resultMap.put(String.valueOf(ar.get('YearOfSale')) + '/' + String.valueOf(ar.get('MonthOfSale')), 
                (Double)ar.get('TotalAmount'));
        }
        
        Map<String, Double> dataMap = new Map<String, Double>();
        Integer currentYear = firstYear;
        Integer currentMonth = 1;

        String resultJS = 'data.addColumn(\'string\', \'Month\');\n';

        while (currentYear <= date.today().year()) {
            resultJS += 'data.addColumn(\'number\', \'' + currentYear + '\');\n';
            currentYear++;
        }

        Boolean isFirstRow = true;
        resultJS += 'data.addRows([';

        // We need to do this so we can fill in blank values with a zero and restrict to the
        // number of years specified in the constant CLOSED_SALES_AMOUNT_MOM_YEARS_SHOWN
        while (currentMonth < 13) {
            currentYear = firstYear;
            Integer yearCount = 1;

            if (isFirstRow == false) {
                resultJS += ',';
            }
            isFirstRow = false;

            resultJS += '\n[\'' + currentMonth + '\'';

            while (currentYear <= date.today().year()) {

                if (resultMap.get(String.valueOf(currentYear) + '/' + String.valueOf(currentMonth)) != null) {
    
                    resultJS += ', ' + resultMap.get(String.valueOf(currentYear) + '/' + String.valueOf(currentMonth));
                } else {
                    resultJS += ', 0';
                }
                
                yearCount++;
                currentYear++;
            }

            resultJS += ']\n';
            currentMonth++;
        }

        resultJS += ']);';

        return resultJS;
    }
    
    // Controller to generate the data for the "Sales Amount by Product Family" chart
    public String getSalesAmountByProduct() {
        String id = this.acct.Id;
        String result = '';
        Map<String, Double> salesByProductFamily = new Map<String, Double>();

        // Get all opportunity line items for all Opportunities associated with this account
        // (can't query OpportunityLineItems directly) and tally them up by product family
        for (Opportunity thisOppty : [SELECT Id, Amount, (SELECT Quantity, TotalPrice, PricebookEntry.product2.Family 
            FROM OpportunityLineItems) FROM Opportunity WHERE Opportunity.AccountId = :id AND IsWon = TRUE]) {
        
            for (OpportunityLineItem oli : thisOppty.OpportunityLineItems) {
        
                if (salesByProductFamily.get(oli.PricebookEntry.product2.Family) != null) {
                    salesByProductFamily.put(oli.PricebookEntry.product2.Family, 
                        salesByProductFamily.get(oli.PricebookEntry.product2.Family) + oli.TotalPrice);
                } else {
                    salesByProductFamily.put(oli.PricebookEntry.product2.Family, oli.TotalPrice);
                }
            }
        }
        
        result += 'data.addRows(' + salesByProductFamily.keySet().size() + ');\n';
        
        Integer count = 0;
        for (String productFamily : salesByProductFamily.keySet()) {
            result += 'data.setValue(' + count + ', 0, \'' + productFamily + '\');\n';
            result += 'data.setValue(' + count + ', 1, ' + salesByProductFamily.get(productFamily) + ');\n';
            count++;
        }
        
        return result;
    }

    // Controller to generate the data for the "Sales Quantity by Product Family" chart
    public String getSalesQuantityByProduct() {
        String id = this.acct.Id;
        String result = '';
        Map<String, Double> qtyByProductFamily = new Map<String, Double>();

        // Get all opportunity line items for all Opportunities associated with this account
        // (can't query OpportunityLineItems directly) and tally them up by product family
        for (Opportunity thisOppty : [SELECT Id, Amount, (SELECT Quantity, TotalPrice, PricebookEntry.product2.Family 
            FROM OpportunityLineItems) FROM Opportunity WHERE Opportunity.AccountId = :id AND IsWon = TRUE]) {
        
            for (OpportunityLineItem oli : thisOppty.OpportunityLineItems) {
        
                if (qtyByProductFamily.get(oli.PricebookEntry.product2.Family) != null) {
                    qtyByProductFamily.put(oli.PricebookEntry.product2.Family, 
                        qtyByProductFamily.get(oli.PricebookEntry.product2.Family) + oli.Quantity);
                } else {
                    qtyByProductFamily.put(oli.PricebookEntry.product2.Family, oli.Quantity);
                }
            }
        }
        
        result += 'data.addRows(' + qtyByProductFamily.keySet().size() + ');\n';
        
        Integer count = 0;
        for (String productFamily : qtyByProductFamily.keySet()) {
            result += 'data.setValue(' + count + ', 0, \'' + productFamily + '\');\n';
            result += 'data.setValue(' + count + ', 1, ' + qtyByProductFamily.get(productFamily) + ');\n';
            count++;
        }
        
        return result;
    }
}