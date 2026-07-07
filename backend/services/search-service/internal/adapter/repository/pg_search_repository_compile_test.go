package repository

import "kz/inflap/backend/services/search-service/internal/app"

var _ app.SearchRepository = (*PGSearchRepository)(nil)
var _ app.IndexRepository = (*PGSearchRepository)(nil)
var _ app.DocumentEventRepository = (*PGSearchRepository)(nil)
