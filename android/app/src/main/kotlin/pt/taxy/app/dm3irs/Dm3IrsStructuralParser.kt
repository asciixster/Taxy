package pt.taxy.app.dm3irs

import java.math.BigDecimal
import java.math.RoundingMode
import java.security.MessageDigest
import java.text.Normalizer

internal data class RecognizedToken(
    val text: String,
    val left: Double,
    val top: Double,
    val right: Double,
    val bottom: Double,
)

internal data class RecognizedPage(
    val number: Int,
    val width: Int,
    val height: Int,
    val tokens: List<RecognizedToken>,
) {
    fun normalizedText(): String = tokens.joinToString(" ") { normalize(it.text) }
}

internal data class Dm3IrsHistoricalResult(
    val taxYear: Int,
    val annexes: Set<String>,
    val categories: Set<String>,
    val categoryBRegime: String?,
    val activityCode: String?,
    val taxableProfitCents: Long?,
    val withholdingCents: Long?,
    val templateVersion: String,
    val templateFingerprint: String,
    val exactCount: Int,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "available" to true,
        "taxYear" to taxYear,
        "annexes" to annexes.sorted(),
        "incomeCategories" to categories.sorted(),
        "categoryBRegime" to categoryBRegime,
        "activityCode" to activityCode,
        "taxableProfitCents" to taxableProfitCents,
        "withholdingCents" to withholdingCents,
        "templateVersion" to templateVersion,
        "templateFingerprint" to templateFingerprint,
        "confidence" to "EXACT",
        "exactCount" to exactCount,
    )
}

internal class UnknownDm3IrsTemplate : Exception()

internal object Dm3IrsStructuralParser {
    const val TEMPLATE_VERSION = "MODELO3_2024_V1"
    const val RUNTIME_VALIDATION_REQUIRED_FIELD_603 = "603"
    private const val EXPECTED_PAGES = 17
    private val money = Regex("^(?:\\d{1,3}(?:[. ]\\d{3})+|\\d+)[,.]\\d{2}$")

    fun parse(pages: List<RecognizedPage>): Dm3IrsHistoricalResult {
        if (pages.size != EXPECTED_PAGES) throw UnknownDm3IrsTemplate()
        val routes = routeAnnexes(pages)
        val annexes = routes.values.toSet().intersect(setOf("A", "C", "H", "SS"))
        if (annexes != setOf("A", "C", "H", "SS")) throw UnknownDm3IrsTemplate()
        if (routes[3] != "A" || routes[5] != "C" || routes[14] != "H" || routes[17] != "SS") {
            throw UnknownDm3IrsTemplate()
        }
        val all = pages.flatMap { it.tokens }
        val year = all.map { it.text }.firstOrNull { it == "2024" }?.toInt()
            ?: throw UnknownDm3IrsTemplate()
        val cPages = pages.filter { routes[it.number] == "C" }
        val cFirst = cPages.firstOrNull() ?: throw UnknownDm3IrsTemplate()
        val regime = checkboxSelection(cFirst, code = "01", yMin = .055, yMax = .095)
            ?.let { "CONTABILIDADE_ORGANIZADA" }
            ?: throw UnknownDm3IrsTemplate()
        val activity = exactTextCell(cFirst, code = "07", xMin = .15, xMax = .24, yMin = .21, yMax = .26, Regex("^\\d{4}$"))
            ?: throw UnknownDm3IrsTemplate()
        val taxableProfit = exactMoneyCell(cPages, "470", .82, .97, .09, .135)
            ?: throw UnknownDm3IrsTemplate()
        val withholding = exactMoneyCell(cPages, "602", .40, .50, .31, .37)
            ?: throw UnknownDm3IrsTemplate()

        // Field 603 is intentionally neither parsed nor exposed. Synthetic
        // support is not runtime evidence and remains gated for a later release.
        val anchors = listOf("MODELO3", "2024", "A@3", "C@5", "H@14", "SS@17", "07", "470", "602")
        val fingerprint = sha256(anchors.joinToString("|"))
        return Dm3IrsHistoricalResult(
            taxYear = year,
            annexes = annexes,
            categories = setOf("A", "B"),
            categoryBRegime = regime,
            activityCode = activity,
            taxableProfitCents = taxableProfit,
            withholdingCents = withholding,
            templateVersion = TEMPLATE_VERSION,
            templateFingerprint = fingerprint,
            exactCount = 10,
        )
    }

    private fun routeAnnexes(pages: List<RecognizedPage>): Map<Int, String> {
        val starts = mutableListOf<Pair<Int, String>>()
        for (page in pages) {
            val text = page.normalizedText()
            if (!text.contains("modelo 3")) continue
            val matches = Regex("\\banexo (ss|[a-z])\\b").findAll(text).map { it.groupValues[1].uppercase() }.toSet()
            if (matches.size == 1) starts += page.number to matches.single()
        }
        val routed = mutableMapOf<Int, String>()
        starts.sortedBy { it.first }.forEachIndexed { index, (start, annex) ->
            val end = starts.getOrNull(index + 1)?.first ?: (pages.size + 1)
            for (number in start until end) routed[number] = annex
        }
        return routed
    }

    private fun checkboxSelection(
        page: RecognizedPage,
        code: String,
        yMin: Double,
        yMax: Double,
    ): RecognizedToken? {
        val codes = page.tokens.filter { it.text == code && it.top in yMin..yMax }
        if (codes.size != 1) return null
        val owner = codes.single()
        val marks = page.tokens.filter {
            it.text.equals("x", ignoreCase = true) &&
                it.top in yMin..yMax &&
                it.left >= owner.right &&
                it.left - owner.right <= .05 &&
                kotlin.math.abs(it.top - owner.top) <= .02
        }
        return marks.singleOrNull()
    }

    private fun exactTextCell(
        page: RecognizedPage,
        code: String,
        xMin: Double,
        xMax: Double,
        yMin: Double,
        yMax: Double,
        pattern: Regex,
    ): String? {
        val owners = page.tokens.filter { it.text == code && it.top in yMin..yMax }
        if (owners.size != 1) return null
        return page.tokens.filter {
            pattern.matches(it.text) && it.left in xMin..xMax && it.top in yMin..yMax
        }.singleOrNull()?.text
    }

    private fun exactMoneyCell(
        pages: List<RecognizedPage>,
        code: String,
        xMin: Double,
        xMax: Double,
        yMin: Double,
        yMax: Double,
    ): Long? {
        val candidates = mutableListOf<String>()
        for (page in pages) {
            val codeOnPage = page.tokens.any { it.text == code && it.top in yMin..yMax }
            if (!codeOnPage) continue
            candidates += page.tokens.filter {
                money.matches(it.text) && it.left in xMin..xMax && it.top in yMin..yMax
            }.map { it.text }
        }
        return candidates.singleOrNull()?.let(::parseMoneyCents)
    }

    internal fun parseMoneyCents(source: String): Long? = try {
        if (!money.matches(source)) return null
        val normalized = source.replace(" ", "").replace(".", "").replace(',', '.')
        BigDecimal(normalized).movePointRight(2).setScale(0, RoundingMode.UNNECESSARY).longValueExact()
    } catch (_: Exception) {
        null
    }

    private fun sha256(value: String): String = MessageDigest.getInstance("SHA-256")
        .digest(value.toByteArray(Charsets.US_ASCII))
        .joinToString("") { "%02x".format(it) }
}

private fun normalize(value: String): String {
    val decomposed = Normalizer.normalize(value, Normalizer.Form.NFKD)
    return decomposed.replace(Regex("\\p{M}+"), "").lowercase().replace(Regex("\\s+"), " ").trim()
}
