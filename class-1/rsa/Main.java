import java.security.*;
import java.util.Base64;

public class Main {
    public static void main(String[] args) throws Exception {
        // 1. 生成 RSA 密钥对
        KeyPairGenerator keyGen = KeyPairGenerator.getInstance("RSA");
        keyGen.initialize(2048);
        KeyPair keyPair = keyGen.generateKeyPair();
        PrivateKey privateKey = keyPair.getPrivate();
        PublicKey publicKey = keyPair.getPublic();

        System.out.println("=== RSA 密钥对（Base64）===");
        System.out.println("私钥: " + Base64.getEncoder().encodeToString(privateKey.getEncoded()));
        System.out.println("公钥: " + Base64.getEncoder().encodeToString(publicKey.getEncoded()));

        // 2. 原始数据
        String originalData = "Hello, 这是需要签名的消息。";
        System.out.println("\n=== 原始数据 ===");
        System.out.println(originalData);

        // 3. 私钥签名
        Signature signer = Signature.getInstance("SHA256withRSA");
        signer.initSign(privateKey);
        signer.update(originalData.getBytes("UTF-8"));
        byte[] signature = signer.sign();
        String signatureBase64 = Base64.getEncoder().encodeToString(signature);
        System.out.println("\n=== 数字签名（Base64）===");
        System.out.println(signatureBase64);

        // 4. 公钥验证（正常）
        Signature verifier = Signature.getInstance("SHA256withRSA");
        verifier.initVerify(publicKey);
        verifier.update(originalData.getBytes("UTF-8"));
        boolean isValid = verifier.verify(signature);
        System.out.println("\n=== 验证结果（原始数据）===");
        System.out.println("签名有效: " + isValid);

        // 5. 篡改数据后验证
        String tamperedData = originalData + "（被篡改）";
        verifier = Signature.getInstance("SHA256withRSA");
        verifier.initVerify(publicKey);
        verifier.update(tamperedData.getBytes("UTF-8"));
        boolean isTamperedValid = verifier.verify(signature);
        System.out.println("\n=== 验证结果（篡改数据）===");
        System.out.println("签名有效: " + isTamperedValid);
    }
}