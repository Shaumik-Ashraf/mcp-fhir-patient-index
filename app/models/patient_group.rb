class PatientGroup
  # Returns a mapping from patient_record_id to a stable 1-based group index.
  # Records not participating in any join are omitted (callers treat absence as nil).
  # Components are ordered by their minimum patient_record_id for stability.
  #
  # @return [Hash<Integer, Integer>]
  def self.index_by_patient_record_id
    edges = PatientJoin.where(qualifier: :has_same_identity_as)
                       .pluck(:from_patient_record_id, :to_patient_record_id)
    return {} if edges.empty?

    parent = {}
    find = ->(x) {
      parent[x] ||= x
      parent[x] == x ? x : parent[x] = find.(parent[x])
    }
    edges.each { |a, b| parent[find.(a)] = find.(b) }

    components = edges.flatten.uniq.group_by { |id| find.(id) }

    sorted_roots = components.keys.sort_by { |root| components[root].min }

    result = {}
    sorted_roots.each.with_index(1) do |root, idx|
      components[root].each { |id| result[id] = idx }
    end
    result
  end

  # Returns true if both records belong to the same existing identity group.
  # Records absent from group_map (i.e. unlinked) are never considered linked.
  #
  # @param [Integer] id_a
  # @param [Integer] id_b
  # @param [Hash<Integer, Integer>] group_map - as returned by index_by_patient_record_id
  # @return [Boolean]
  def self.already_linked?(id_a, id_b, group_map:)
    group_a = group_map[id_a]
    group_b = group_map[id_b]
    group_a.present? && group_a == group_b
  end
end
