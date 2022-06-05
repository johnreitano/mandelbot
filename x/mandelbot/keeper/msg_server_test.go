package keeper_test

import (
	"context"
	"testing"

	sdk "github.com/cosmos/cosmos-sdk/types"
	keepertest "github.com/johnreitano/mandelbot/testutil/keeper"
	"github.com/johnreitano/mandelbot/x/mandelbot/keeper"
	"github.com/johnreitano/mandelbot/x/mandelbot/types"
)

func setupMsgServer(t testing.TB) (types.MsgServer, context.Context) {
	k, ctx := keepertest.MandelbotKeeper(t)
	return keeper.NewMsgServerImpl(*k), sdk.WrapSDKContext(ctx)
}
