#!/usr/bin/env ruby

require 'set'

def shortest_chain(word1, word2, word_list)
  dictionary = Dictionary.new(word_list)
  from_start, = searches = [Search.new(word1, dictionary), Search.new(word2, dictionary)]
  until searches.first.exhausted?
    if found = searches.first.extend_towards(searches.last)
      return searches.first == from_start ? found : found.reverse
    end
    searches.rotate!
  end
  nil
end

class Dictionary
  def initialize(words)
    @words_to_masks = {}
    @masks_to_words = {}
    words.each do |word|
      @words_to_masks[word] = word_masks = masks(word)
      word_masks.each do |mask|
        (@masks_to_words[mask] ||= []) << word
      end
    end
  end

  def neighbours(word)
    @words_to_masks.fetch(word).flat_map { |mask| @masks_to_words.fetch(mask) } - [word]
  end

  private

  def masks(word)
    lower_word = word.downcase
    0.upto(lower_word.size - 1).map do |i|
      lower_word.dup.tap do |mask|
        mask[i] = "_"
      end
    end
  end
end

class Search
  def initialize(from_word, dictionary)
    @dictionary = dictionary
    @chain_tips = { from_word => [from_word] }
    @seen = Set.new([from_word])
  end

  def exhausted?
    @chain_tips.empty?
  end

  def extend_towards(other_chain)
    new_chain_tips = {}
    @chain_tips.each do |tip, chain|
      @dictionary.neighbours(tip).each do |neighbour|
        unless @seen.include?(neighbour)
          if matching = other_chain.ending_on(neighbour)
            return chain + matching.reverse
          end
          new_chain_tips[neighbour] = chain.dup.push(neighbour)
        end
      end
    end
    @seen.merge(new_chain_tips.keys)
    @chain_tips = new_chain_tips
    nil
  end

  def ending_on(word)
    @chain_tips[word]
  end
end

def main
  unless ARGV.size == 3
    abort "usage: #{$0} word1 word2 dict"
  end

  word1, word2, dictfile = ARGV

  if word1.size != word2.size
    abort "words must be the same size"
  end

  words = File.read(dictfile).split("\n").select { |w| w.size == word1.size }
  puts "#{words.size} words of length #{word1.size} in dictionary"
  if found = shortest_chain(word1, word2, words)
    puts "Found solution:"
    puts found.join(" -> ")
  else
    abort "No solution found"
  end
end

def profile(meth)
  require 'ruby-prof'
  result = RubyProf.profile do
    send(meth)
  end
  printer = RubyProf::GraphHtmlPrinter.new(result)
  fname = "/tmp/profile.html"
  File.open(fname, 'w') do |f|
    printer.print(f)
  end
  system("open '#{fname}'")
end

if __FILE__ == $0
  ENV.key?('PROFILE') ? profile(:main) : main
end

# Test cases

# cat -> dog (easy)
# ruby -> code (moderate)
# house -> shout (hard)
# turkey -> carrot (harder)
# ravine -> turkey (hardest)
