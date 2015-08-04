#!/usr/bin/env ruby

require 'set'

class Dictionary
  def initialize(words)
    @words_to_masks = {}
    @masks_to_words = {}
    words.each do |word|  # TODO: uniq(&:downcase), for Gold/gold, which are both in dict
      @words_to_masks[word] = word_masks = masks(word)
      word_masks.each do |mask|
        (@masks_to_words[mask] ||= []) << word
      end
    end
  end

  def include?(word)
    @words_to_masks.has_key?(word)
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

def shortest_chain(word1, word2, word_list)
  dictionary = Dictionary.new(word_list)

  chains_from_start = Chains.new(word1, dictionary)
  while chains_from_start.any?
    if found = chains_from_start.ending_on(word2)
      return found
    end
    chains_from_start.extend!
  end
  nil
end

class Chains
  def initialize(from_word, dictionary)
    @dictionary = dictionary
    @chain_tips = { from_word => [from_word] }
    @seen = Set.new([from_word])
  end

  def any?
    @chain_tips.any?
  end

  def extend!
    old_chain_tips = @chain_tips
    @chain_tips = {}
    old_chain_tips.each do |tip, chain|
      @dictionary.neighbours(tip).each do |neighbour|
        unless @seen.include?(neighbour)
          @chain_tips[neighbour] = chain.dup.push(neighbour)
          @seen << neighbour
        end
      end
    end
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
# house -> house (no solution?)
