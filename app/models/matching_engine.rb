class MatchingEngine
  # Returns a Float 0.0..1.0 representing identity similarity between two patient records.
  #
  # Weights:
  #   SSN (exact match)       0.55 — strong unique identifier, not corrupted in simulations
  #   birth_date (exact)      0.20 — stable field, not corrupted in simulations
  #   last_name (similarity)  0.15 — may be corrupted by typos
  #   first_name (similarity) 0.10 — may be corrupted by typos
  #
  # @param [PatientRecord] a
  # @param [PatientRecord] b
  # @return [Float]
  def match_score(a, b)
    score = 0.0
    score += 0.55 if exact_match?(a.social_security_number, b.social_security_number)
    score += 0.20 if exact_match?(a.birth_date, b.birth_date)
    score += 0.15 * string_similarity(a.last_name, b.last_name)
    score += 0.10 * string_similarity(a.first_name, b.first_name)
    score.clamp(0.0, 1.0)
  end

  # Returns true if the match score for the two records meets or exceeds the threshold.
  #
  # @param [PatientRecord] a
  # @param [PatientRecord] b
  # @param [Float] threshold
  # @return [Boolean]
  def match?(a, b, threshold:)
    match_score(a, b) >= threshold
  end

  private

  def exact_match?(val_a, val_b)
    val_a.present? && val_b.present? && val_a == val_b
  end

  # Normalized Levenshtein similarity in [0.0, 1.0].
  def string_similarity(str_a, str_b)
    return 0.0 if str_a.blank? || str_b.blank?
    a = str_a.downcase
    b = str_b.downcase
    return 1.0 if a == b
    max_len = [ a.length, b.length ].max
    1.0 - (levenshtein(a, b).to_f / max_len)
  end

  # Wagner-Fischer algorithm: O(n*m) time, O(min(n,m)) space.
  def levenshtein(a, b)
    a, b = b, a if a.length < b.length
    prev = (0..b.length).to_a
    a.each_char.with_index(1) do |char_a, i|
      curr = [ i ]
      b.each_char.with_index(1) do |char_b, j|
        cost = char_a == char_b ? 0 : 1
        curr << [ prev[j - 1] + cost, prev[j] + 1, curr[j - 1] + 1 ].min
      end
      prev = curr
    end
    prev[b.length]
  end
end
