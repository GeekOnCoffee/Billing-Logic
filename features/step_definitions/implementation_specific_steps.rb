Given /^I have the following subscriptions:$/ do |table|
  # table is a Cucumber::Ast::Table
  strategy.current_state =  table.raw.map do |row|
    paid_until_date = str_to_date(row[3])
    products = str_to_product_formatting(row[0])
    products.each { |product| product.billing_cycle.anniversary = paid_until_date}
    billing_cycle = str_to_billing_cycle(row[0], paid_until_date)
    ostruct = OpenStruct.new(
               :identifier => row[0],
               :products =>  products,
               :paid_until_date =>  paid_until_date,
               :billing_cycle => billing_cycle,
               :active_or_pending? => row[1] =~ /active/,
              )
    def ostruct.refundable_payment_amount(foo)
      @refundable_payment_amount || 0.0
    end
    ostruct
  end
end

When /^I change to having: (nothing|.*)$/ do |products|
  strategy.desired_state = products == 'nothing' ? [] : products
end
