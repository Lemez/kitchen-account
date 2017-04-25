require_relative('./script.rb')

@global_data = get_data({:offline=>true})

@fields = %w(S.NO TYPE DATE ACCOUNT DESCRIPTION DEBIT CREDIT)

write_summary_data(@global_data,@fields)