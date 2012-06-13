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
      | added products          | action                                                 |
      | A @ $30/mo              | add (A @ $30/mo) on 03/15/12                             |
      | A @ $30/mo, B @ $40/mo  | add (A @ $30/mo) on 03/15/12, add (B @ $40/mo) on 03/15/12 |

    Scenario Outline: Transitioning a subscription to independent payments
      Given I support Independent Payment Strategy
      And   Today is 3/15/12
      And   I have the following subscriptions:
        | (A @ $30/mo & B @ $40/mo & C @ $25/mo) @ $95/mo | active | and the next billing date is on | 4/1/12 |
     When  I change to having: <desired state>
     Then  I expect the following action: <action>
     Examples: Removing all products
       | desired state | action               |
       | nothing       | cancel [(A @ $30/mo & B @ $40/mo & C @ $25/mo) @ $95/mo] now |

     Examples: Removing partial products
       | desired state                | action                  |
       | A @ $30/mo                   | remove (B @ $40/mo & C @ $25/mo) from [(A @ $30/mo & B @ $40/mo & C @ $25/mo) @ $95/mo] now   |
       | B @ $40/mo & C @ $25/mo      | remove (A @ $30/mo) from [(A @ $30/mo & B @ $40/mo & C @ $25/mo) @ $95/mo] now   |

   Scenario Outline: Removing a product
     Given I support Independent Payment Strategy
     And   Today is 3/15/12
     And   I have the following subscriptions:
     # | product names | billing cycle        | status    | #comments                                                | next billing date   |
       | A @ $30/mo | active    | with current permissions and the next billing date is on | 4/1/12              |
       | B @ $20/mo | active    | with current permissions and the next billing date is on | 4/20/12             |
       | C @ $50/yr | cancelled | with permissions expiring in the future on               | 4/25/12             |
       | F @ $10/mo | cancelled | with permissions expiring today                          | 3/15/12             |
       | G @ $15/mo | cancelled | with permissions expired in the past on                  | 3/13/12             |
     When  I change to having: <desired state>
     Then  I expect the following action: <action>
     Examples: Removing all products
       | desired state | action               |
       | nothing       | cancel [A @ $30/mo] now, cancel [B @ $20/mo] now |

     Examples: Removing partial products
       | desired state                | action                  |
       | A @ $30/mo                   | cancel [B @ $20/mo] now   |
       | B @ $20/mo                   | cancel [A @ $30/mo] now   |

     Examples: Re-adding a cancelled product C that expires in the future
       | desired state                      | action                     |
       | A @ $30/mo, B @ $20/mo, C @ $50/mo | add (C @ $50/mo) on 04/25/12 |

     Examples: Re-adding a cancelled product that expires today
       | desired state                        | action                     |
       | A @ $30/mo, B @ $20/mo, F @ $10/mo   | add (F @ $10/mo) on 03/15/12 |
       
     Examples: Re-adding a cancelled product that expired in the past
       | desired state                        | action                     |
       | A @ $30/mo, B @ $20/mo, G @ $15/mo   | add (G @ $15/mo) on 03/15/12 |

     Examples: Re-adding & removing product
       | desired state           | action                                            |
       | A @ $30/mo, C @ $50/mo  | cancel [B @ $20/mo] now, add (C @ $50/mo) on 04/25/12 |

     Examples: Adding, Re-adding & removing product
       | desired state                        | action                                                                        |
       | A @ $30/mo, C @ $50/mo, D @ $40/mo   | cancel [B @ $20/mo] now, add (C @ $50/mo) on 04/25/12, add (D @ $40/mo) on 03/15/12 |

     Examples: changing the periodicity of product A from monthly to yearly
       | desired state            | action                                                                            |
       | A @ $99/yr, B @ $20/mo   | cancel [A @ $30/mo] now, add (A @ $99/yr) on 04/01/13 with initial payment set to $99.00 |

     Examples: 
      Adding a new product D, 
      Re-adding a cancelled product C, 
      Changing the periodicity of A product, 
      Removing product B
       | desired state                      | action                                                                                                                                                           |
       | A @ $60/yr, C @ $50/yr, D @ $40/yr | cancel [A @ $30/mo] now, add (A @ $60/yr) on 04/01/13 with initial payment set to $60.00, cancel [B @ $20/mo] now, add (C @ $50/yr) on 04/25/12, add (D @ $40/yr) on 03/15/12 |

       #  """
       #                                                                         cancel A @ $30 now, 
       #                                                                         add A @ $60 on 04/01/12 renewing every 1 year, 
       #                                                                         cancel B @ $20 now, 
       #                                                                         add C @ $50 on 04/25/12 renewing every 1 year, 
       #                                                                         add D @ $40 on 03/15/12 renewing every 1 year 
       #                                                                         """                       |

