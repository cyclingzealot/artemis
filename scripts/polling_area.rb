require 'set'

class PollingArea
    attr_accessor   :ed
    attr_accessor   :polling_area
    attr_reader     :results

    # Results of votes by affiliation

    @@allAffilations = Set.new



    def initialize(ed, polling_area)
        self.ed = ed
        self.polling_area = polling_area
        @results = {}
    end


    def addResults(affiliation, votes)
        @results[affiliation] = 0 if @results[affiliation].nil?

        @results[affiliation] += votes.to_i

        @@allAffilations << affiliation
    end


    def getTotalVotes()
        @results.values.sum
    end


    def getWinnerHash()
        winner = @results.max_by{|affiliation, votes| votes}
        return {winner[0] => winner[1]}
    end

    def getWinnerAffiliation()
        getWinnerHash().keys.first
    end

    def getWinnerPct()
        (getWinnerHash().values.first.to_f)/getTotalVotes()
    end

    def self.getAllAffiliations
        @@allAffilations
    end

    def toCsv()
        csvHash = {
            :ed             => self.ed,
            :polling_area   => self.polling_area,
            :total_votes    => self.getTotalVotes(),
            :winner         => self.getWinnerAffiliation(),
            :winner_pct     => self.getWinnerPct(),
        }

        byebug if self.getWinnerPct < 0.1

        resultsAllAffiliations = Hash[@@allAffilations.map {|x| [x, nil]}]

        @results.each {|affiliation, votes|
            resultsAllAffiliations[affiliation] = votes
        }

        csvHash.merge(resultsAllAffiliations)

    end




end
