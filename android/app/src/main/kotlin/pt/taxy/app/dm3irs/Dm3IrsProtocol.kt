package pt.taxy.app.dm3irs

import pt.taxy.app.efatura.FactIntSecurityMaterial

internal enum class Dm3IrsReadOperation(val wireName: String, val responseRoot: String) {
    CHECK_DELIVERY("checkEntregaDeclMobileRequest", "checkEntregaDeclMobileResponse"),
    GET_RECEIPT("obterReceiptMobileRequest", "obterReceiptMobileResponse"),
    GET_DECLARATION("obterDeclaracaoMobileRequest", "obterDeclaracaoMobileResponse"),
}

internal object Dm3IrsProtocol {
    const val ENDPOINT = "https://servicos.portaldasfinancas.gov.pt:411/ws/dm3irsMobileService/"
    const val HOST = "servicos.portaldasfinancas.gov.pt"
    const val MOBILE_NAMESPACE = "https://servicos.portaldasfinancas.gov.pt/dm3irsmobile/schemas"
    const val DECLARATION_NAMESPACE = "https://servicos.portaldasfinancas.gov.pt/dm3irs/schemas"
    private const val SOAP_NAMESPACE = "http://schemas.xmlsoap.org/soap/envelope/"
    private const val AUTH_NAMESPACE = "http://at.pt/wsp/auth"
    private const val WSSE_NAMESPACE = "http://schemas.xmlsoap.org/ws/2002/12/secext"
    private const val ACTOR = "http://at.pt/actor/SPA"
    val allowedOperations = Dm3IrsReadOperation.entries.map { it.wireName }.toSet()
    val prohibitedOperations = setOf("submeterDeclaracaoMobileRequest")

    fun soapAction(operation: Dm3IrsReadOperation): String = "tns:${operation.wireName}"

    fun checkDeliveryBody(year: Int, nif: String): String {
        require(year == 2024) { "Only the runtime-confirmed history year is supported" }
        require(Regex("^\\d{9}$").matches(nif)) { "Invalid NIF" }
        return "<sch:ano-fiscal>$year</sch:ano-fiscal><sch:nif>${xml(nif)}</sch:nif>"
    }

    fun receiptBody(identifier: String, nif: String): String {
        require(Regex("^[1-9]\\d{0,30}$").matches(identifier)) { "Invalid declaration reference" }
        require(Regex("^\\d{9}$").matches(nif)) { "Invalid NIF" }
        return "<sch:declaracao>${xml(identifier)}</sch:declaracao><sch:nif>${xml(nif)}</sch:nif>"
    }

    fun declarationBody(identifier: String, nifA: String, nifB: String?): String {
        require(Regex("^[1-9]\\d{0,30}$").matches(identifier)) { "Invalid declaration reference" }
        require(Regex("^\\d{9}$").matches(nifA)) { "Invalid NIF" }
        require(nifB == null || Regex("^\\d{9}$").matches(nifB)) { "Invalid NIF" }
        return "<sch:modelo><sch1:declaracao>${xml(identifier)}</sch1:declaracao>" +
            "<sch1:nifA>${xml(nifA)}</sch1:nifA>" +
            (nifB?.let { "<sch1:nifB>${xml(it)}</sch1:nifB>" } ?: "") +
            "<sch1:consignacaoIRS>false</sch1:consignacaoIRS>" +
            "<sch1:consignacaoIVA>false</sch1:consignacaoIVA>" +
            "<sch1:checkIban>false</sch1:checkIban>" +
            "<sch1:indicadorAssociarIban>E</sch1:indicadorAssociarIban></sch:modelo>"
    }

    fun envelope(
        operation: Dm3IrsReadOperation,
        username: String,
        security: FactIntSecurityMaterial,
        body: String,
    ): String {
        require(operation.wireName in allowedOperations)
        require(Regex("^\\d{9}(?:/\\d{1,4})?$").matches(username)) { "Invalid login identity" }
        return "<?xml version=\"1.0\" encoding=\"utf-8\"?>" +
            "<S:Envelope xmlns:S=\"$SOAP_NAMESPACE\" xmlns:at=\"$AUTH_NAMESPACE\" " +
            "xmlns:sch=\"$MOBILE_NAMESPACE\" xmlns:sch1=\"$DECLARATION_NAMESPACE\">" +
            "<S:Header><wss:Security xmlns:wss=\"$WSSE_NAMESPACE\" S:actor=\"$ACTOR\" at:Version=\"2\">" +
            "<wss:UsernameToken><wss:Username>${xml(username)}</wss:Username>" +
            "<wss:Password Digest=\"${xml(security.encryptedDigest)}\">${xml(security.encryptedPassword)}</wss:Password>" +
            "<wss:Nonce>${xml(security.encryptedNonce)}</wss:Nonce>" +
            "<wss:Created>${xml(security.created)}</wss:Created></wss:UsernameToken>" +
            "</wss:Security></S:Header><S:Body><sch:${operation.wireName}>$body" +
            "</sch:${operation.wireName}></S:Body></S:Envelope>"
    }

    private fun xml(value: String): String = value
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace("\"", "&quot;")
        .replace("'", "&apos;")
}
