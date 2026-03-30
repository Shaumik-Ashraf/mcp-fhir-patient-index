module InfernoTests
  class PatientGroup < Inferno::TestGroup
    id :patient_group
    title 'Patient'
    description <<~DESCRIPTION
      These tests validate the API endpoints and FHIR response format for the Patient resource.
    DESCRIPTION

    test do
      title 'Server returns a bundle of Patient resources from a read-all/search interaction'
      description %(
        Verify that a bundle of Patient resources can be fetched from the server. This is
        formally a type-level search interaction, but can also be referred to as a read-all
        or index operation.

        Test expects a 200 response, a FHIR bundle resource, at least 1 Patient resource in the
        bundle, and only valid Patient resources in the bundle.
      )

      output :patient_id

      run do
        fhir_search(FHIR::Patient)

        assert_response_status(200)
        assert_resource_type(FHIR::Bundle)
        assert resource.entry.select { |entry| entry.resource.resourceType == 'Patient' }.count >= 1,
               "Bundle response must contain at least 1 Patient resource"
        assert_valid_bundle_entries(resource_types: 'Patient')

        output patient_id: resource.entry.find { |entry| entry.resource.resourceType == 'Patient' }.resource.id
      end
    end

    test do
      title 'Server returns requested Patient resource from the Patient read interaction'
      description %(
        Verify that Patient resources can be read from the server. Expects a 200 response that includes a Patient
        resource whose ID matches the requested patient ID.

        By default, the requested patient ID will be the first patient from the previous patient search test.
      )

      input :patient_id,
            title: 'Patient ID'

      # Named requests can be used by other tests
      makes_request :patient

      run do
        skip_if patient_id.empty?, "No Patient IDs found"

        fhir_read(:patient, patient_id, name: :patient)

        assert_response_status(200)
        assert_resource_type(:patient)
        assert resource.id == patient_id,
               "Requested resource with id #{patient_id}, received resource with id #{resource.id}"
      end
    end

    test do
      title 'Patient resource is valid'
      description %(
        Verify that the Patient resource returned from the server is a valid FHIR resource.
      )
      # This test will use the response from the :patient request in the
      # previous test
      uses_request :patient
      output :patient_for_match

      run do
        output patient_for_match: resource.to_json

        assert_resource_type(:patient)
        assert_valid_resource
      end
    end

    # NOTE: The next two tests are positive-case tests, assuming
    # a match will be found, and therefore asserts for at least
    # one patient record. However this could be split into 3 tests:
    # REST infrastructure test, positive case test (>= 1 match),
    # and negative case test (0 matches).
    test do
      title 'Server handles Patient $match operation'
      description %(
        Verify FHIR R4 Core [$match operation](https://hl7.org/fhir/R4/operation-patient-match.html)
        by submitting a $match request for the same patient returned from the patient read test.

        Also see [FHIR operations specification](https://hl7.org/fhir/R4/operations.html#request).

        This test checks for an HTTP response status 200, a FHIR Bundle response body, at least
        1 patient resource in the bundle, and no resources besides Patient and OperationOutcome in bundle.
      )
      input :patient_for_match,
            title: "Patient for $match test",
            description: %(
                   Override the resource parameter in $match test request body; otherwise the test
                   uses the same patient retrieved from the read test.
            ),
            optional: true
      makes_request :patient_match

      run do
        patient_param = FHIR.from_contents(patient_for_match)

        skip_if patient_param.nil? || patient_param.resourceType != 'Patient',
                '`patient_for_match` parameter was not parsed into a FHIR Patient resource.'

        parameters = FHIR::Parameters.new(
          {
            parameter: [
              {
                name: "resource",
                resource: patient_param
              }
            ]
          }
        )

        fhir_operation('/Patient/$match', body: parameters, name: :patient_match)

        assert_response_status(200)
        assert_resource_type(FHIR::Bundle)
        assert resource.entry.select { |entry| entry.resource.resourceType == 'Patient' }.count >= 1,
               'Bundle response must contain at least 1 Patient resource'
        assert_valid_bundle_entries(resource_types: ['Patient', 'OperationOutcome'])
      end
    end

    test do
      title 'MPI server returns a match grade in Patient $match operation'
      description %(
        See [$match operation](https://hl7.org/fhir/R4/operation-patient-match.html).

        This optional test checks for the match-grade extension and score in Bundle.entry.search
        where Bundle.entry.resource.resourceType is Patient from the previous test's $match request.

        This is only required by MPI servers.
      )
      uses_request :patient_match
      optional

      run do
        skip_if response.nil?,
                'No Patient $match request was made'

        assert resource.entry.select { |entry| entry.resource.resourceType == 'Patient' }.all? { |entry|
          entry.search&.extension&.any? { |ext| ext.url = 'http://hl7.org/fhir/StructureDefinition/match-grade' } &&
            entry.search&.score
        }, 'Bundle response entries must contain match-grade'
      end
    end

    test do
      title 'Server accepts a direct Patient resource in $match operation request body'
      description %(
        [FHIR operations specification](https://hl7.org/fhir/R4/operations.html#request) allows
        replacing the Parameters resource with a Patient resource in the request body
        for [$match](https://hl7.org/fhir/R4/operation-patient-match.html).

        This test checks for an HTTP response status 200, a FHIR Bundle response body, at least
        1 patient resource in the bundle, and no resources besides Patient and OperationOutcome in bundle.
      )
      input :patient_for_match,
            title: "Patient for $match test",
            description: %(
                   Override the resource parameter in $match test request body; otherwise the test
                   uses the same patient retrieved from the read test.
            ),
            optional: true

      run do
        patient_param = FHIR.from_contents(patient_for_match)

        skip_if patient_param.nil? || patient_param.resourceType != 'Patient',
                '`patient_for_match` parameter was not parsed into a FHIR Patient resource.'

        fhir_operation('/Patient/$match', body: patient_param)

        assert_response_status(200)
        assert_resource_type(FHIR::Bundle)
        assert resource.entry.select { |entry| entry.resource.resourceType == 'Patient' }.count >= 1,
               'Bundle response must contain at least 1 Patient resource'
        assert_valid_bundle_entries(resource_types: ['Patient', 'OperationOutcome'])
      end
    end

    test do
      title 'Server accepts a count parameter in $match operation'
      description %(
        The [$match operation](https://hl7.org/fhir/R4/operation-patient-match.html) specifies
        an optional count parameter, which specifies the maximum number of patient resources
        that may be in the return bundle.

        This test checks for an HTTP response status 200, a FHIR Bundle response body, at most
        2 patient resources in the bundle, and no resources besides Patient and OperationOutcome in bundle.
      )
      input :patient_for_match,
            title: "Patient for $match test",
            description: %(
                   Override the resource parameter in $match test request body; otherwise the test
                   uses the same patient retrieved from the read test.
            ),
            optional: true

      run do
        patient_param = FHIR.from_contents(patient_for_match)
        count_param = 2

        skip_if patient_param.nil? || patient_param.resourceType != 'Patient',
                '`patient_for_match` parameter was not parsed into a FHIR Patient resource.'

        parameters = FHIR::Parameters.new(
          {
            parameter: [
              {
                name: "resource",
                resource: patient_param
              },
              {
                name: "count",
                valueInteger: count_param
              }
            ]
          }
        )

        fhir_operation('/Patient/$match', body: parameters)

        assert_response_status(200)
        assert_resource_type(FHIR::Bundle)
        assert resource.entry.select { |entry| entry.resource.resourceType == 'Patient' }.count <= count_param,
               "Bundle response contains at most #{count_param} Patient resources"
        assert_valid_bundle_entries(resource_types: ['Patient', 'OperationOutcome'])
      end
    end

    test do
      title 'Server accepts an onlyCertainMatches parameter in $match operation'
      description %(
        The [$match operation](https://hl7.org/fhir/R4/operation-patient-match.html) specifies
        an optional onlyCertainMatches parameter, which specifies the maximum number of patient resources
        that may be in the return bundle.

        This test checks for an HTTP response status 200, a FHIR Bundle response body, and no resources
        besides Patient and OperationOutcome in bundle.

        The FHIR specification does not specify what "certain match" means and leaves that detail up to
        the implementation. Since this test is only validating the FHIR specification, the fact that
        only "certain matches" are being returned must be confirmed by the developer.
      )
      input :patient_for_match,
            title: "Patient for $match test",
            description: %(
                   Override the resource parameter in $match test request body; otherwise the test
                   uses the same patient retrieved from the read test.
            ),
            optional: true

      run do
        patient_param = FHIR.from_contents(patient_for_match)

        skip_if patient_param.nil? || patient_param.resourceType != 'Patient',
                '`patient_for_match` parameter was not parsed into a FHIR Patient resource.'

        parameters = FHIR::Parameters.new(
          {
            parameter: [
              {
                name: "resource",
                resource: patient_param
              },
              {
                name: "onlyCertainMatches",
                valueBoolean: true
              }
            ]
          }
        )

        fhir_operation('/Patient/$match', body: parameters)

        assert_response_status(200)
        assert_resource_type(FHIR::Bundle)
        assert_valid_bundle_entries(resource_types: ['Patient', 'OperationOutcome'])
      end
    end
  end
end
