#!/usr/bin/env ruby

require 'capybara'
require 'capybara/poltergeist'
require 'capybara/dsl'

require 'csv'
require "google_drive"

# require 'rspec'
# require 'rspec/expectations'

require_relative('./csv')
require_relative('./mail')
require_relative('./secret')

include Capybara::DSL
# include RSpec::Matchers

Capybara.default_driver = :poltergeist
MONTHS = %w(January February March April May June July August September October November December)


###login page

def get_data(options={:offline=>false})
	if options[:offline]
		get_data_offline_from_csvs
	else
		login_get_data
	end
end

def login_get_data
	p "getting data online"

	visit ("https://fs.auroville.org.in")

	user = find('input[name="username"]')
	pwd = find('input[name="pwd"]')

	user.send_keys(PF_USER)
	pwd.send_keys(PF_PASS)

	find('input[value="Sign In"]').click

	#accounts page
	@fields = %w(S.NO TYPE DATE ACCOUNT DESCRIPTION DEBIT CREDIT)

	page.all(:xpath, '//option[contains(text(), "102296")]').first.select_option
	sleep 3

	this_month = MONTHS.index(Time.now.strftime("%B"))

	@global_data = []

	(this_month+1).times do |month_i|
		# 1.times do |month_i|

		@data = []
		month = month_i
		# month = month_i + 3
		@month = MONTHS[month]; p @month
		@date = Date.parse("#{@month} 2017").strftime("%m-%y"); p @date


		page.all(:xpath, '//option[contains(text(),"' + @month + '")]').first.select_option
		sleep 3	

		page.all('tbody').each_with_index do |table,i|
			if i==4

				size = table.all('tr').count
				table.all('tr').each_with_index do |tr, tr_index|

					case tr_index
					when 0,1,2
						next

					when 3
						debit=tr.all('td')[-2].text.to_f
						credit=tr.all('td')[-1].text.to_f
						@data << {"OPENING BALANCE" => [debit,credit]}
					
					when 4..(size-3)
					
						row = {}; @fields.each{|f| row[f]=""}  

						tr.all('td').each_with_index{|td,td_index| 
							row[@fields[td_index]]=td.text
						} 

						@data << row
						@global_data << row

					when (size-2)
						debit=tr.all('td')[-2].text.to_f
						credit=tr.all('td')[-1].text.to_f
						@data << {"PERIOD TOTALS" => [debit,credit]}
					when (size-1)
						debit=tr.all('td')[-2].text.to_f
						credit=tr.all('td')[-1].text.to_f
						@data << {"CLOSING BALANCE" => [debit,credit]}
					end
				end
			end
		end

		# write_to_local_csv(@global_data,@fields,"all")
		
	end

	@global_data
	# mail(@global_data)
end


