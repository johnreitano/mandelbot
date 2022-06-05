package keeper_test

import (
	"testing"

	testkeeper "github.com/johnreitano/mandelbot/testutil/keeper"
	"github.com/johnreitano/mandelbot/x/mandelbot/types"
	"github.com/stretchr/testify/require"
)

func TestGetParams(t *testing.T) {
	k, ctx := testkeeper.MandelbotKeeper(t)
	params := types.DefaultParams()

	k.SetParams(ctx, params)

	require.EqualValues(t, params, k.GetParams(ctx))
}
