module Spellcheck
  def self.suggestions(word)
    out = %x[echo '#{word}' | aspell -a --ignore-case]
    raise "Error encountered while executing 'aspell'" if $?.exitstatus > 0
    # Based on Ispell output
    # > echo 'knoledge' | aspell -a --ignore-case
    # @(#) International Ispell Version 3.1.20 (but really Aspell 0.60.6)
    # & knoledge 12 0: knowledge, knowledge's, pledge, ledge, kludge, sledge
    # NOTE: the regex needs improvement
    out.scan(/[a-z\']+(?=,|\z)/i)
  end
end

