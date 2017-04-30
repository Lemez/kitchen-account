@accounts_in = {
	"106112K - JONATHAN DANIELA WALTON" => "Daniela/Jonathan",
	"251630C - WHITE ANT STUDIO/FABIAN" => "Elvira/Fabian",
	"106246K - JOST ELKE DANIEL RODARY" => "Elke/Daniel",
	"0533C - PITCHANDIKULAM SMALL PROJECTS/ELVIRAANI" => "PF Small Projects"
}
@accounts_out = {
	"0373K - PT PURCHASING SERVICE" => "Pour Tous"
}

@debiting = [
"LE GOURMET DN [BAKERY",
"GAS BOTTLE BILLING",
'PT PURCHASING SERVICE'
]

M_ABBR = %w(May Jun Jul Aug Sep Oct Nov Dec Jan Feb Mar Apr)
M_PAYMENTS = %w(05 06 07 08 09 10 11 12 01 02 03 04)
TABLE_HEADINGS = %w(S.NO TYPE DATE ACCOUNT DESCRIPTION DEBIT CREDIT)

def get_data_offline_from_csvs
		p "getting data offline"
		@data = []
		
		CSV.foreach("./csv/all-kitchen-accounts.csv","r") do |csv_row|
			next if csv_row[0]=="S.NO"
			row = {}; TABLE_HEADINGS.each{|f| row[f]=""}
			csv_row.each_with_index do |item,index| 
				row[TABLE_HEADINGS[index]]=item
			end

			@data << row
		end

		@data
end


def write_to_local_csv(data,month)
	CSV.open("csv/#{month}-kitchen-accounts.csv",'wb', col_sep: ",") do |csvfile|
		csvfile << FIELDS
		data.each do |record|
			csvfile << record.values			
		end
	end
end

	# {"S.NO"=>"14348", "TYPE"=>"MT", "DATE"=>"01-02-2017", "ACCOUNT"=>"0373K - PT PURCHASING SERVICE", "DESCRIPTION"=>"MT 01/02/17 - BN:4 - 2017-02-1", "DEBIT"=>"-493.71", "CREDIT"=>""}

def write_annual_data(data)
	@records = {}
	CSV.open("csv/annual-2017.csv",'wb', col_sep: ",") do |csvfile|
		header = ["Account"]
		M_ABBR.each do |month|
			header << [month,""]
		end

		csvfile << header.flatten
	
		descs = data.collect{|record|record["DESCRIPTION"]}

		descs.each_with_index do |desc,i|
			@month = ''

			if desc[0..1]=="MT"
				@month = Date.parse(desc.split("-")[0].strip).strftime("%m")
			else 
				desc = desc.downcase
				@found = false

				M_ABBR.each do |m| 
					next if @found
					if desc.include?(m.downcase)
						m_index = desc.index(m.downcase)
						@month = Date.parse(desc[m_index..(m_index+2)].capitalize).strftime("%m")	
						@found=true
					end
				end
			end

			if @month.empty?
				@month = Date.parse(data[i]["DATE"]).strftime("%m")
			end


			payee = data[i]["ACCOUNT"].split(" - ")[-1]
			payee = 'other' if payee.nil?
			@records[payee] = {} if @records[payee].nil?
			@records[payee][@month] = [] if @records[payee][@month].nil?
			relevant_entry = (data[i]["CREDIT"].empty? ? data[i]["DEBIT"] : data[i]["CREDIT"])
			desc = desc.split("-").last if @debiting.include?(payee)
			@records[payee][@month] << [relevant_entry,desc]

		end

		@in = @records.reject{|k,v| @debiting.include?(k)}
		@out = @records.select{|k,v| @debiting.include?(k)}

		grand_totals = []
		[@in,@out].each do |records|
			@totals = {}
			M_PAYMENTS.each {|m|@totals[m]=[0]}

			records.each_pair do |payee,payments| 
				@to_write = [payee]
				
					M_PAYMENTS.each do |m|
						
						if payments.has_key?(m)

							amount = payments[m].map(&:first).map(&:to_f).reduce(&:+).round(0)
							comment = payments[m].map(&:last).join(" / ")
							
							@to_write << [amount,comment]

							p "snap!: #{m};#{payee};#{amount}; #{comment}"

							@totals[m] << amount
						else
							@to_write << [" "," "]
							p "nope!: #{m};#{payee}"
						end 


					end

					csvfile << @to_write.flatten
				end
				
				totals_array = @totals.map{|k,v| [v.reduce(&:+)," "]}
				grand_totals << totals_array.map(&:first)

				csvfile << ["TOTALS",totals_array].flatten
				csvfile << [""]
			end

			first,second = grand_totals[0],grand_totals[1]
			the_real_thing = []
			the_cash_thing = []

			cash_amount = -1625
			
			first.each_with_index do |j,index|
				the_real_thing << [j + second[index]," "]
				cash_amount += (j+second[index])
				the_cash_thing << [cash_amount," "]
			end

			csvfile << ["OVERALL", the_real_thing].flatten
			csvfile << ["Cumulative", the_cash_thing].flatten
		end
	end

def write_summary_data(data)
	
	@incoming = data.reject{|record|record["CREDIT"].empty?}
	@outgoing = data.reject{|record|record["DEBIT"].empty?}

	@flows = {
			"Income"=> 
				{'column'=>"CREDIT",
				'data'=>@incoming,
				'acc'=>@accounts_in}, 
			"Expenditure"=> 
				{'column'=>"DEBIT",
				'data'=>@outgoing,
				'acc'=>@accounts_out}
			}

	CSV.open("csv/summary-#{Date.today.to_s}.csv",'wb', col_sep: ",") do |csvfile|
		
		@flows.keys.each do |type|	

			csvfile << [type]
			csvfile << ["Account",'Date',"Amount","Description"]

			@direction = @flows[type]['column']
			@payments = {'other'=>[]}

			@account = @flows[type]['acc']
			@account.values.each{|name| @payments[name]=[]} 


			@flows[type]['data'].each do |record|
				acc = record["ACCOUNT"]

				if @account.has_key?(acc)
					@payments[@account[acc]] << [record["DATE"],record[@direction],record["DESCRIPTION"]]	
				else
					payee = record["ACCOUNT"].split(" - ")[-1]

					if payee.nil?
							@payments['other'] << [record["DATE"],record[@direction],record["DESCRIPTION"]]
					elsif acc
						payee = record["ACCOUNT"].split(" - ")[-1]
						@payments[payee] = [] if @payments[payee].nil?
						@payments[payee] << [record["DATE"],record[@direction],record["DESCRIPTION"]]
					end
					# p payee
					# p record
				end	
			end

			people = @payments.keys(&:titleize).sort
			people.each do |person|
				@payments[person].each do |entry|
					csvfile << [person,entry].flatten
				end
			end
		end

		csvfile << [""]
	end
end