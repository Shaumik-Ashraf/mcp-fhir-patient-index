import { Grid, html } from "gridjs"

document.addEventListener("turbo:load", () => {
  const container = document.getElementById("patient-grid")
  if (!container) return

  // Clear any previously rendered grid (Turbo navigation re-fires turbo:load)
  container.innerHTML = ""

  new Grid({
    columns: [
      { id: "first_name", name: "First Name", sort: true },
      { id: "last_name",  name: "Last Name",  sort: true },
      { id: "birth_date", name: "Birth Date", sort: true },
      { id: "linked_records_count", name: "Linked Records", sort: false },
      { id: "uuid", hidden: true },
      {
        name: "Actions",
        sort: false,
        formatter: (_, row) => {
          const uuid = row.cells[4].data
          return html(`
            <a href="/patient_records/${uuid}" class="btn btn-sm btn-outline-secondary me-1">View</a>
            <a href="/patient_records/${uuid}/edit" class="btn btn-sm btn-outline-primary me-1">Edit</a>
            <a href="/patient_records/${uuid}"
               data-turbo-method="delete"
               data-turbo-confirm="Permanently delete this patient?"
               class="btn btn-sm btn-outline-danger">Delete</a>
          `)
        }
      }
    ],
    server: {
      url: "/patient_records.json",
      then: (data) => data.data.map(r => [r.first_name, r.last_name, r.birth_date, r.linked_records_count, r.uuid]),
      total: (data) => data.total
    },
    search: {
      server: {
        url: (prev, keyword) => {
          const url = new URL(prev, window.location.href)
          url.searchParams.set("search", keyword)
          return url.toString()
        }
      }
    },
    sort: {
      multiColumn: false,
      server: {
        url: (prev, columns) => {
          const url = new URL(prev, window.location.href)
          const colNames = ["first_name", "last_name", "birth_date"]
          if (columns.length > 0) {
            url.searchParams.set("sort_column", colNames[columns[0].index] ?? "last_name")
            url.searchParams.set("sort_direction", columns[0].direction === 1 ? "asc" : "desc")
          }
          return url.toString()
        }
      }
    },
    pagination: {
      limit: 25,
      server: {
        url: (prev, page, limit) => {
          const url = new URL(prev, window.location.href)
          url.searchParams.set("page", page + 1)
          url.searchParams.set("per_page", limit)
          return url.toString()
        }
      }
    }
  }).render(container)
})
