// Code generated by mockery v2.3.0. DO NOT EDIT.

package mocks

import (
	meilisearch "github.com/meilisearch/meilisearch-go"
	mock "github.com/stretchr/testify/mock"
)

// APIKeys is an autogenerated mock type for the APIKeys type
type APIKeys struct {
	mock.Mock
}

// Get provides a mock function with given fields:
func (_m *APIKeys) Get() (*meilisearch.Keys, error) {
	ret := _m.Called()

	var r0 *meilisearch.Keys
	if rf, ok := ret.Get(0).(func() *meilisearch.Keys); ok {
		r0 = rf()
	} else {
		if ret.Get(0) != nil {
			r0 = ret.Get(0).(*meilisearch.Keys)
		}
	}

	var r1 error
	if rf, ok := ret.Get(1).(func() error); ok {
		r1 = rf()
	} else {
		r1 = ret.Error(1)
	}

	return r0, r1
}
