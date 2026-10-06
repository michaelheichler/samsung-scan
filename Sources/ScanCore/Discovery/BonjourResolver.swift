import Dispatch
import dnssd
import Foundation

// Because dnssd must deallocate a service on the queue that delivers its events.
actor BonjourResolver {
    private let queue = DispatchSerialQueue(label: "SamsungScan.BonjourResolver")

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        queue.asUnownedSerialExecutor()
    }

    func resolve(name: String, type: String, domain: String, timeout: Duration) async -> DiscoveredScanner? {
        let pending = PendingResolve(name: name)
        var reference: DNSServiceRef?
        let status = DNSServiceResolve(
            &reference, 0, 0, name, type, domain,
            { _, _, _, error, _, hostTarget, port, _, _, context in
                guard let context else { return }
                let pending = Unmanaged<PendingResolve>.fromOpaque(context).takeUnretainedValue()
                guard error == kDNSServiceErr_NoError, let hostTarget else { return pending.finish(nil) }
                let host = String(cString: hostTarget)
                pending.finish(DiscoveredScanner(name: pending.name, host: host, port: Int(UInt16(bigEndian: port))))
            },
            Unmanaged.passUnretained(pending).toOpaque())
        guard status == kDNSServiceErr_NoError, let reference else { return nil }
        defer {
            DNSServiceRefDeallocate(reference)
            withExtendedLifetime(pending) {}
        }
        DNSServiceSetDispatchQueue(reference, queue)
        let timer = Task {
            try? await Task.sleep(for: timeout)
            pending.finish(nil)
        }
        defer { timer.cancel() }
        guard let target = await pending.value() else { return nil }
        return DiscoveredScanner(
            name: target.name, host: target.host, port: target.port, addresses: Self.ipv4Addresses(of: target.host))
    }

    // So that a scanner listed by address in the system file is not added twice.
    private static func ipv4Addresses(of host: String) -> [String] {
        var hints = addrinfo()
        hints.ai_family = AF_INET
        hints.ai_socktype = SOCK_STREAM
        var list: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(host, nil, &hints, &list) == 0, let list else { return [] }
        defer { freeaddrinfo(list) }
        return sequence(first: list) { $0.pointee.ai_next }.compactMap { entry in
            var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            guard getnameinfo(
                entry.pointee.ai_addr, entry.pointee.ai_addrlen, &buffer, socklen_t(buffer.count), nil, 0,
                NI_NUMERICHOST) == 0
            else { return nil }
            return String(decoding: buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
        }
    }
}
