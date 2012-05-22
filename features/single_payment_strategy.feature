Feature: Single Payment Strategy
  As a service provider
  in order to provide a simple overview of your subscription
  I want to offer a single payment for all the customer's subscriptions

  Scenario Outline: Creating a new recurring payment profile
    Given I support a Single Payment Strategy
    And   Today is 3/1/12
    And   I don't have any subscriptions
    When  I change to having: <added products>
    Then  I expect the following action: <action>
    Examples:
      | added products          | action                 |
      | A @ $30/mo              | add (A @ $30/mo) @ $30/mo on 03/01/12 |
      | A @ $30/mo, B @ $40/mo  | add (A @ $30/mo & B @ $40/mo) @ $70/mo on 03/01/12|

  Scenario Outline: Removing a product from your recurring payment profile
    Given I support a Single Payment Strategy
    And   Today is 3/10/12
    And   I have the following subscriptions:
    # | billing profile                   | status    | #comments                                                | next billing date   |
      | (A @ $30/mo & B @ $20/mo & C @ $20/mo) @ $70/mo | active    | with current permissions and the next billing date is on | 4/1/12              |
    When  I change to having: <desired state>
    Then  I expect the following action: <action>
    Examples: Removing all products
      | desired state | action               |
      | nothing       | cancel (A @ $30/mo & B @ $20/mo & C @ $20/mo) @ $70/mo now |

    Examples: Removing partial products
      | desired state             | action                                                                                  |
      | A @ $30/mo                | remove B @ $20/mo & C @ $20/mo from (A @ $30/mo & B @ $20/mo & C @ $20/mo) @ $70/mo now |
      | A @ $30/mo, C @ $20/mo    | remove B @ $20/mo from (A @ $30/mo & B @ $20/mo & C @ $20/mo) @ $70/mo now              |

  Scenario Outline: Changing a current payment profile to a different product
    Given I support a Single Payment Strategy
    And   Today is 3/10/12
    And   I have the following subscriptions:
    # | billing profile       | status    | #comments                                                | next billing date   |
      | (A @ $30/mo) @ $30/mo | active    | with current permissions and the next billing date is on | 4/1/12              |
    When  I change to having: <desired state>
    Then  I expect the following action: <action>
   Examples: When changing to a lower priced products we want to cancel the current subscription and
             create a new one for the lesser price starting at the end of the previous
      | desired state | action               |
      | B @ $20/mo    | cancel (A @ $30/mo) @ $30/mo now, add (B @ $20/mo) @ $20/mo on 03/10/12 |

   Examples: When changing to a higher priced products we want to cancel the current subscription and
             create a new one with the first payment prorated for the portion of the month paid
      | desired state | action               |
      | B @ $40/mo    | cancel (A @ $30/mo) @ $30/mo now, add (B @ $40/mo) @ $40/mo on 03/10/12 |

  Scenario Outline: Changing to a greater periodicity of a current product
    Given I support a Single Payment Strategy
    And   Today is 4/10/12
    And   I have the following subscriptions:
    # | billing profile       | status    | #comments                                                | next billing date   |
      | (A @ $30/mo) @ $30/mo | active    | with current permissions and the next billing date is on | 5/1/12              |
    When  I change to having: <desired state>
    Then  I expect the following action: <action>
   Examples: When changing to a greater periodicity we want to cancel the current profile &
             create a new one crediting the customer for amount paid but unused
      | desired state | action               |
      | A @ $300/yr    | cancel (A @ $30/mo) @ $30/mo now, add (A @ $300/yr) @ $300/yr on 04/10/13 with initial payment set to $280 |

  Scenario Outline: Changing to a lesser periodicity of a current product
    Given I support a Single Payment Strategy
    And   Today is 3/10/12
    And   I have the following subscriptions:
    # | billing profile         | status    | #comments                                                | next billing date   |
      | (A @ $300/yr) @ $300/yr | active    | with current permissions and the next billing date is on | 4/1/12              |
    When  I change to having: <desired state>
    Then  I expect the following action: <action>
   Examples: When changing to a lesser periodicity we want to cancel the current profile &
             schedule the new one starting at the end to the current payment profile
      | desired state | action               |
      | A @ $30/mo    | cancel (A @ $300/yr) @ $300/yr now, add (A @ $30/mo) @ $30/mo on 04/01/12 |

  Scenario Outline: Changing to a different product with greater periodicity than the current product
    Given I support a Single Payment Strategy
    And   Today is 3/10/12
    And   I have the following subscriptions:
    # | billing profile       | status    | #comments                                                | next billing date   |
      | (A @ $30/mo) @ $30/mo | active    | with current permissions and the next billing date is on | 4/1/12              |
    When  I change to having: <desired state>
    Then  I expect the following action: <action>
   Examples: When changing to a greater periodicity we want to cancel the current profile &
             create a new one crediting the customer for amount paid but unused
      | desired state | action               |
      | B @ $300/yr    | cancel (A @ $30/mo) @ $30/mo now, add (B @ $300/yr) @ $300/yr on 03/10/12 |

  Scenario Outline: Changing to a different product with lesser periodicity than the current product
    Given I support a Single Payment Strategy
    And   Today is 3/10/12
    And   I have the following subscriptions:
    # | billing profile         | status    | #comments                                                | next billing date   |
      | (A @ $300/yr) @ $300/yr | active    | with current permissions and the next billing date is on | 4/1/12              |
    When  I change to having: <desired state>
    Then  I expect the following action: <action>
   Examples: When changing to a lesser periodicity we want to cancel the current profile &
             schedule the new one starting at the end to the current payment profile
      | desired state | action               |
      | B @ $30/mo    | cancel (A @ $300/yr) @ $300/yr now, add (B @ $30/mo) @ $30/mo on 03/10/12 |

