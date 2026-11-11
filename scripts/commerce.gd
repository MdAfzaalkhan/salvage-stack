extends RefCounted
# Native integrations intentionally unconfigured. No simulated ad/purchase success.
# Each platform must get its own app/ad IDs, verified billing and consent setup.
const ANDROID_APP_ID = ""
const INTERSTITIAL_UNIT_ID = ""
const REMOVE_ADS_PRODUCT_ID = ""
var status = "Monetisation awaiting platform configuration"

func interstitial_available() -> bool:
	return false

func between_rounds() -> bool:
	return false

func purchase_remove_ads() -> bool:
	return false

func restore_purchases() -> bool:
	return false
