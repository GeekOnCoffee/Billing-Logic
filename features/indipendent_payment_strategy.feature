Feature: Independent Payment Strategy
  As a service provider
  in order to provide an a-la-carte menu of products and consistent charges
  I want to offer independent payments & subscriptions for each product

  Scenario Outline: Adding a product
    Given I support Independent Payment Strategy
    And   Today is 3/15/12
    And   I don't have any subscriptions
    When  I change to having: <added products>
    Then  I expect the following action: <action>
    Examples:
      | added products                                | action                 |
      | A @ $30 every 1 month                         | add A @ $30 on 03/15/12 renewing every 1 month |
      | A @ $30 every 1 month, B @ $40 every 1 month  | add A @ $30 on 03/15/12 renewing every 1 month |
      | A @ $30 every 1 month, B @ $40 every 1 month  | add B @ $40 on 03/15/12 renewing every 1 month |

   Scenario Outline: Removing a product
     Given I support Independent Payment Strategy
     And   Today is 3/15/12
     And   I have the following subscriptions:
     # | product names | billing cycle        | status    | #comments                                                | next billing date   |
       | A @ $30       | billed every 1 month | active    | with current permissions and the next billing date is on | 4/1/12              |
       | B @ $20       | billed every 1 month | active    | with current permissions and the next billing date is on | 4/20/12             |
       | C @ $50       | billed every 1 year  | cancelled | with permissions expiring in the future on               | 4/25/12             |
       | F @ $10       | billed every 1 month | cancelled | with permissions expiring today                          | 3/15/12             |
       | G @ $15       | billed every 1 month | cancelled | with permissions expired in the past on                  | 3/13/12             |
     When  I change to having: <desired state>
     Then  I expect the following action: <action>
     Examples: Removing all products
       | desired state | action               |
       |               | cancel A @ $30 now   |
       |               | cancel B @ $20 now   |

     Examples: Removing partial products
       | desired state               | action               |
       | A @ $30 every 1 month       | cancel B @ $20 now   |
       | B @ $20 every 1 month       | cancel A @ $30 now   |

     Examples: Re-adding a cancelled product C that expires in the future
       | desired state                                                         | action                  |
       | A @ $30 every 1 month, B @ $20 every 1 month, C @ $50 every 1 month   | add C @ $50 on 04/25/12 renewing every 1 month |

     Examples: Re-adding a cancelled product that expires today
       | desired state                                                         | action                  |
       | A @ $30 every 1 month, B @ $20 every 1 month, F @ $10 every 1 month   | add F @ $10 on 03/15/12 renewing every 1 month |
       
     Examples: Re-adding a cancelled product that expired in the past
       | desired state                                                         | action                  |
       | A @ $30 every 1 month, B @ $20 every 1 month, G @ $15 every 1 month   | add G @ $15 on 03/15/12 renewing every 1 month |

     Examples: Re-adding & removing product
       | desired state                                                         | action                  |
       | A @ $30 every 1 month, C @ $50 every 1 month                          | add C @ $50 on 04/25/12 renewing every 1 month |
       | A @ $30 every 1 month, C @ $50 every 1 month                          | cancel B @ $20 now      |

     Examples: Adding, Re-adding & removing product
       | desired state                                                         | action                  |
       | A @ $30 every 1 month, C @ $50 every 1 month, D @ $40 every 1 month   | add C @ $50 on 04/25/12 renewing every 1 month |
       | A @ $30 every 1 month, C @ $50 every 1 month, D @ $40 every 1 month   | add D @ $40 on 03/15/12 renewing every 1 month |
       | A @ $30 every 1 month, C @ $50 every 1 month, D @ $40 every 1 month   | cancel B @ $20 now      |

     Examples: changing the periodicity of product A from monthly to yearly
       | desired state                                                         | action                   |
       | A @ $99 every 1 year, B @ $20 every 1 month                           | cancel A @ $30 now                                  |
       | A @ $99 every 1 year, B @ $20 every 1 month                           | add A @ $99 on 04/01/12 renewing every 1 year       |

     Examples: 
      Adding a new product D, 
      Re-adding a cancelled product C, 
      Changing the periodicity of A product, 
      Removing product B
       | desired state                                                         | action                   |
       | A @ $60 every 1 year, C @ $50 every 1 year, D @ $40 every 1 year     | cancel A @ $30 now       |
       | A @ $60 every 1 year, C @ $50 every 1 year, D @ $40 every 1 year     | add A @ $60 on 04/01/12 renewing every 1 year |
       | A @ $60 every 1 year, C @ $50 every 1 year, D @ $40 every 1 year     | cancel B @ $20 now       |
       | A @ $60 every 1 year, C @ $50 every 1 year, D @ $40 every 1 year     | add C @ $50 on 04/25/12 renewing every 1 year |
       | A @ $60 every 1 year, C @ $50 every 1 year, D @ $40 every 1 year     | add D @ $40 on 03/15/12 renewing every 1 year |

