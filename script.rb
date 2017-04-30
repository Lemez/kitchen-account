#!/usr/bin/env ruby

require 'capybara'
require 'capybara/poltergeist'
require 'capybara/dsl'

require 'csv'
require "google_drive"

require_relative('./csv')
require_relative('./mail')

include Capybara::DSL
Capybara.default_driver = :poltergeist

unless $heroku
	require_relative('./secret') 
	$pf_user = PF_USER
	$pf_pass = PF_PASS
end

MONTHS = %w(January February March April May June July August September October November December)
YEARS = %w(2016 2017)
MONTHYEARS = %w(May-2016 June-2016 July-2016 August-2016 September-2016 October-2016 November-2016 December-2016 January-2017 February-2017 March-2017 April-2017)
FIELDS = %w(S.NO TYPE DATE ACCOUNT DESCRIPTION DEBIT CREDIT)

###login page

def get_all_table_data(page)
	@data = []
	if @year != @lastyear
		year = page.all(:xpath, '//option[contains(text(),"' + @lastyear + '")]').first
		year.select_option
		sleep 3	
	end

	month = page.all(:xpath, '//option[contains(text(),"' + @month + '")]').first
	month.select_option
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
					
						row = {}; FIELDS.each{|f| row[f]=""}  

						tr.all('td').each_with_index{|td,td_index| 
							row[FIELDS[td_index]]=td.text
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
end

def get_data(options={:offline=>nil, :latest=>nil})
	if options[:offline]
		get_data_offline_from_csvs
	elsif options[:latest]
		login_get_data(options)
	else
		login_get_data
	end
end

def get_first_row_of_page
end

def login_get_data(options={:latest=>nil})
	p "getting data online - login"

	visit ("https://fs.auroville.org.in")

	user = find('input[name="username"]')
	pwd = find('input[name="pwd"]')

	user.send_keys($pf_user)
	pwd.send_keys($pf_pass)

	find('input[value="Sign In"]').click

	#accounts page
	p "logged in"
	account_path = page.all(:xpath, "//select[@name='accountnumber']/option[@value='102296']").first

	if account_path.has_text?("KITCHEN")
		account_path.select_option
		p "acc selected"
	else
		p "acc not selected"
	end

	# page.all('a', :text => 'Reload').first.click
	# page.all(:xpath, '//option[contains(text(), "KITCHEN")]').first.trigger('click')

	this_month = MONTHS.index(Time.now.strftime("%B"))

	@global_data = []
	@lastyear = ''

	unless options[:latest]
		MONTHYEARS.each do |month_year|
			
			@month,@year = month_year.split("-").map{|x|x.gsub("-","")}
		
			get_all_table_data(page)

			@date = Date.parse("#{@month}-#{@year}").strftime("%y-%m"); p @date
			write_to_local_csv(@data,"#{@date}")
			write_to_local_csv(@global_data,"all")

			@lastyear = @year
		end
		[@global_data,'']
	else
		@month = Date.today.strftime("%B")
		@last_month = (Date.today - 7).strftime("%B")

		@year = Date.today.strftime("%Y")
		@last_year = (Date.today - 7).strftime("%Y")

		if @month!=@last_month 
			@month = @last_month
			get_all_table_data(page)
		end

		get_all_table_data(page)

		[@global_data,@data[-1]]
		
	end
end


