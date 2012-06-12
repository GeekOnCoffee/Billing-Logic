Feature: Same Day Cancellation Policy
  As a service provider
  In order to provide a fair experience to the customers and not overcharging them when making multiple changes on the same day.
  I want to offer a grace period for for cancellation, during which I'll issue a refund

  Scenario Outline: User subscribes, then cancels within the grace period
    Given I support <strategy>
    And   The cancellation grace period is of <grace period>
    And   Today is 3/15/12
    And   I have the following subscriptions:
     #| product names | status | comments                                                 | next billing date |
      | A @ $30/mo    | active | with current permissions and the next billing date is on | 4/15/12           |
    And   I made the following payment: <payment made>
    When  I change to having: <desired state>
    Then  I expect the following action: <actions>
    Examples: A customer that have made a payment of $30 the same day of cancellation
      | strategy                     | grace period | payment made                    | desired state | actions                    |
      | Independent Payment Strategy | 24 hours     | paid $30 for A @ $30 on 3/15/12 | nothing       | cancel and disable A @ $30/mo with refund $30.00 now |
      | a Single Payment Strategy    | 24 hours     | paid $30 for A @ $30 on 3/15/12 | nothing       | cancel and disable A @ $30/mo with refund $30.00 now |

    Examples: A customer that made a refundable payment greater than the monthly payment because of a startup fee
      | strategy                     | grace period | payment made                    | desired state | actions                   |
      | Independent Payment Strategy | 24 hours     | paid $40 for A @ $30 on 3/15/12 | nothing       | cancel and disable A @ $30/mo with refund $40.00 now |
      | a Single Payment Strategy    | 24 hours     | paid $40 for A @ $30 on 3/15/12 | nothing       | cancel and disable A @ $30/mo with refund $40.00 now |

    Examples: A customer that made a refundable payment lesser than the monthly payment because of an initial discount
      | strategy                     | grace period              | payment made                    | desired state | actions                   |
      | Independent Payment Strategy | 24 hours                  | paid $20 for A @ $30 on 3/15/12 | nothing       | cancel and disable A @ $30/mo with refund $20.00 now |
      | a Single Payment Strategy    | 24 hours                  | paid $20 for A @ $30 on 3/15/12 | nothing       | cancel and disable A @ $30/mo with refund $20.00 now |


  Scenario Outline: User subscribes, then cancels not within the grace period
    Given I support <strategy>
    And   The cancellation grace period is of <grace period>
    And   Today is 3/15/12
    And   I have the following subscriptions:
     #| product names | status | comments                                                 | next billing date |
      | A @ $30/mo    | active | with current permissions and the next billing date is on | 4/15/12           |
    And   I made the following payment: <payment made>
    When  I change to having: <desired state>
    Then  I expect the following action: <action>
    And   I do not expect the following action: <inaction>
    Examples: A customer that have made a payment just outside of the grace period by 1 second
      | strategy                     | grace period | payment made                    | desired state | action                    | inaction |
      | Independent Payment Strategy | 24 hours     | paid $30 for A @ $30 on 3/14/12 | nothing       | cancel A @ $30/mo now        | refund $30 to A @ $30/mo now |
      | a Single Payment Strategy    | 24 hours     | paid $30 for A @ $30 on 3/14/12 | nothing       | cancel A @ $30/mo now        | refund $30 to A @ $30/mo now |

