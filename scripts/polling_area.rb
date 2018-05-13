class PollingArea
    attr_accessor   :ed
    attr_accessor   :polling_area
    attr_reader     :total_votes
    attr_reader     :results

    # Results of votes by affiliation



    def initialize()
        @results = {}
    end


    def addResults(affiliation, votes)
        @results[affiliation] = 0 if @results[affiliation].nil?

        @results[affiliation] += votes.to_i
    end




end
