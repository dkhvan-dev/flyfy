package dto

type ActivityTaxonomyItemResponse struct {
	Slug   string `json:"slug"`
	Name   string `json:"name"`
	NameRu string `json:"nameRu"`
	NameKk string `json:"nameKk"`
}

type ActivityCategoryResponse struct {
	Slug          string                         `json:"slug"`
	Name          string                         `json:"name"`
	NameRu        string                         `json:"nameRu"`
	NameKk        string                         `json:"nameKk"`
	Aliases       []string                       `json:"aliases,omitempty"`
	Subcategories []ActivityTaxonomyItemResponse `json:"subcategories,omitempty"`
	SystemTags    []ActivityTaxonomyItemResponse `json:"systemTags,omitempty"`
}

type ActivityCategoryListResponse struct {
	Items []ActivityCategoryResponse `json:"items"`
}
