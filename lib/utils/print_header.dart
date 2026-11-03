/// Shops whose estimate prints carry no shop header.
///
/// The HDD number is the first `REF_NO` in `HDD_MAST`, read on the dashboard
/// and kept on the company provider. For the shops listed here the Tag
/// Estimate and WH Tag Estimate prints (POS roll and A4 PDF) leave out the
/// shop name, address lines, city, PIN and mobile; everything else prints.
const Set<String> kNoHeaderHdds = {
  "VK289NEPH",
  "VK103NEVK",
  "VK061NEVK",
  "HM208NEPK",
  "AB000NEAB",
  "VS220NPVS",
};

/// Whether the shop header should be left off the print for [hddNo].
bool hidePrintHeader(String hddNo) => kNoHeaderHdds.contains(hddNo.trim());

/// Shops that take the slim POS estimate: the per-gram rate is repeated up
/// in the Date / Tag No / Item block, the ghat weight always prints,
/// labelled "Wst", and the pcs, ghat %, labour rate, labour amount and
/// other amount lines are left off. Every other shop gets the full receipt.
const Set<String> kSlimReceiptHdds = {"VS220NPVS"};

/// Whether [hddNo] takes the slim POS estimate.
bool slimReceipt(String hddNo) => kSlimReceiptHdds.contains(hddNo.trim());
