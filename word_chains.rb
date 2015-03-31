#!/usr/bin/env ruby
# encoding: UTF-8
require 'optparse'
require 'colored'

module WordChains

  class Application

    def initialize(argv)
      @params, @file = parse_options(argv)
      @word_candidates = []
      @iteration_count = 0
    end

    def run
      start_at = Time.now

      @file.empty? ? @word_candidates = load_dictionary_file('wordlist.txt') : @word_candidates = load_dictionary_file(@file)

      if @params[:start].length != @params[:stop].length
        puts 'Start and end words must have same length'.red
        exit
      end

      if verbose?
        puts 'Trying to build chain from ' + @params[:start].green + ' to ' + @params[:stop].green
        puts 'Starting with' + @word_candidates.size.to_s.green + 'words'
      end

      #filter initial candidates - keep only words with correct length
      @word_candidates = @word_candidates.keep_if { |w| w.length == @params[:start].length }
      @word_candidates = @word_candidates.uniq

      puts 'Remaining candidates: ' + @word_candidates.size.to_s.green if verbose?

      build_chain(@params[:start], @params[:stop])

      if verbose?
        puts '-------'
        puts 'Stats: '
        puts 'Took ' + (Time.now - start_at).to_s.green + ' seconds.'
        puts 'Used ' + @iteration_count.to_s.green + ' recursion steps.'
      end
    end

    protected

    def verbose?
      @params[:verbose]
    end

    def build_chain(start, stop)
      recursion_hash = []
      recursion_hash << ->(available_words) { {used_words: [start], next_words: find_next_candidates(start, available_words)} }

      until recursion_hash.empty?

        current_step = recursion_hash.shift.call(@word_candidates)

        if current_step[:next_words].include?(stop)
          puts 'Put down that coffee - we\'re done!'.green
          puts ((current_step[:used_words] + [stop]).join(', ')).green
          recursion_hash.clear
        else
          # Find next words for each next word
          current_step[:next_words].each do |from_word|
            used_words = current_step[:used_words] + [from_word]
            recursion_hash << ->(available_words) { {used_words: used_words, next_words: find_next_candidates(from_word, available_words)} }
          end
          #remove used words and next words from candidates list
          @word_candidates -= current_step[:used_words] + current_step[:next_words]
        end
      end
    end


    def find_next_candidates(from_word, available_candidates)
      @iteration_count += 1

      next_words = []
      available_candidates.each do |candidate_word|
        character_distance = 0
        #calculate "distance" of characters
        candidate_word.length.times do |i|
          character_distance += 1 if candidate_word[i] != from_word[i]
        end
        #only accept if distance is one
        next_words << candidate_word if character_distance == 1
      end

      if verbose?
        puts 'Found next words from ' + from_word.green + ' -> ' + next_words.join(', ').green
        puts 'No next words - abandon path'.red if next_words.empty?
      end

      next_words
    end

    def parse_options(argv)
      params = {}
      begin
        parser = OptionParser.new
        parser.banner = 'Usage: word_chains.rb [options] [file]'
        parser.separator 'Mandatory options:'
        parser.on('-s', '--start START_WORD', 'Enter a start word') { |start| params[:start] ||= start }
        parser.on('-e', '--stop STOP_WORD', 'Enter a stop word') { |stop| params[:stop] ||= stop }
        parser.on('-v', '--verbose', 'Verbose output') { params[:verbose] = true }
        parser.on('-h', '--help', 'Display this screen') do
          puts parser
          exit
        end
        parser.separator 'If no file is supplied it detects based on wordlist.txt'
        files = parser.parse!(argv)
        mandatory = [:start, :stop]
        missing = mandatory.select { |param| params[param].nil? }
        raise OptionParser::InvalidOption unless missing.empty?
      rescue OptionParser::InvalidOption, OptionParser::MissingArgument
        puts $!.to_s
        puts parser
        exit
      end
      [params, files]
    end

    def load_dictionary_file(filename)
      content = []
      File.open(filename, 'r:UTF-8').each_line { |line| content.push line.encode!('UTF-8', 'UTF-8', invalid: :replace).chomp.downcase }
      content
    end
  end
end

application = WordChains::Application.new(ARGV)
application.run
