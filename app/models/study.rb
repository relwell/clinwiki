class Study < ActiveRecord::Base
  searchkick

  self.primary_key = 'nct_id'
  scope :started_between, lambda {|sdate, edate| where("start_date >= ? AND created_at <= ?", sdate, edate )}
  scope :changed_since,   lambda {|cdate| where("last_changed_date >= ?", cdate )}
  scope :completed_since, lambda {|cdate| where("completion_date >= ?", cdate )}
  scope :sponsored_by,    lambda {|agency| joins(:sponsors).where("sponsors.agency LIKE ?", "#{agency}%")}

    def self.all_nctids
      all.collect{|s|s.nct_id}
    end

    def average_rating
      if reviews.size==0
        0
      else
        reviews.average(:rating).round(2)
      end
    end

    def intervention_names
      interventions.collect{|x|x.name}.join(', ')
    end

    def condition_names
      conditions.collect{|x|x.name}.join(', ')
    end

    def self.retrieve(value=nil)
      col=[]
      begin
        case
        when value.blank?
          response = HTTParty.get('http://aact-dev.herokuapp.com/api/v1/studies?per_page=25')
          response.each{|r| col << instantiate_from(r)} if response
        when value.downcase.match(/^nct/)
          response = [HTTParty.get("http://aact-dev.herokuapp.com/api/v1/studies/#{value}")]
          study=instantiate_from(response.first['study']) if response
          col << study if study
        else
          # Search by MeSH Term
          mesh_response = [HTTParty.get("http://aact-dev.herokuapp.com/api/v1/studies?mesh_term=#{value.gsub(" ", "+")}&per_page=25")]
          # And also by Organization
          org_response = [HTTParty.get("http://aact-dev.herokuapp.com/api/v1/studies?organization=#{value.gsub(" ", "+")}&per_page=25")]
          response=(JSON.parse(mesh_response.to_json, object_class: OpenStruct) \
                    + JSON.parse(org_response.to_json, object_class: OpenStruct)).flatten.uniq
          response.each{|study|
            study.prime_address= ''
            study.reviews = Review.where('nct_id = ?',study['nct_id'])
            study.reveiws = [] if study.reviews.nil?
            study.average_rating = (study.reviews.size == 0 ? 0 : study.reviews.average(:rating).round(2))
            col << study
          }
        end
      rescue
        col
      end
      col
    end

    def self.instantiate_from(hash)
      nct_id=hash['nct_id']
      study=JSON.parse(hash.to_json, object_class: OpenStruct)
      study.prime_address = ''
      study.reviews = Review.where('nct_id = ?',nct_id)
      study.reviews = [] if study.reviews.nil?
      study.average_rating = (study.reviews.size == 0 ? 0 : study.reviews.average(:rating).round(2))
      study
     end

	end