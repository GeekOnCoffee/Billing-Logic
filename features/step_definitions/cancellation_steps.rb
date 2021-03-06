And /^I made the following payment: paid (#{MONEY}) for (#{PRODUCT_FORMATTING}) on (#{DATE})$/ do |amount, profile_object, payment_date|
  payment_date = str_to_date(payment_date)
  strategy.current_state.each do |profile|
    profile.products.each do |product|
      if product.name == profile_object.first.name
        create_payment_for_profile_at_date(profile, amount, payment_date)
      end
    end
  end
end

Given /^The cancellation grace period is of (\d+) (hour|day|month|week|year)s?$/ do |amount, length|
  grace_period(amount.to_i * 60 * 60)
end


# NOTE: this one might be replaced by the inline version above
# keeping this method around for the moment. Diego
# And /^I made the following payments:$/ do |table|
#   # table is a Cucumber::Ast::Table
#   table.raw.map do |row|
#     strategy.current_state.each do |profile|
#       profile.products.each do |product| 
#         if product.name == str_to_product_formatting(row[0]).name
#           profile.last_payment = OpenStruct.new(:amount => row[1],
#                                                 :payment_date => str_to_date(row[2]),
#                                                 :refundable? => (Date.today - str_to_date(row[2])).to_i <= grace_period)
#           def profile.last_payment_refundable?
#             last_payment.refundable?
#           end
#           
#           def profile.last_payment_amount
#             last_payment.amount
#           end
#         end
#       end
#     end
#   end
# end


