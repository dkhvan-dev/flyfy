package savedsearch

import "context"

type Repository interface {
	Search(context.Context, Query) (Page, error)
}
