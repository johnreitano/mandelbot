package keeper

import (
	"github.com/johnreitano/mandelbot/x/mandelbot/types"
)

var _ types.QueryServer = Keeper{}
