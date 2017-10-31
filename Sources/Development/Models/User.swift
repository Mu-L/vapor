import Foundation
import Async
import HTTP
import Leaf
import Vapor
import Fluent
import SQLite

final class Pet: Model {
    var id: UUID?
    var name: String
    var ownerID: UUID

    var owner: Parent<Pet, User> {
        return parent(idKey: \Pet.ownerID)
    }
}

final class User: Model, ResponseRepresentable {
    var id: UUID?
    var name: String
    var age: Int
//    var child: User?
//    var futureChild: Future<User>?
    
    func makeResponse(for request: Request) throws -> Response {
        let body = try  Body(JSONEncoder().encode(self))
        
        return Response(body: body)
    }

    init(name: String, age: Int) {
        self.name = name
        self.age = age
    }

    var pets: Children<User, Pet> {
        return children(foreignKey: "ownerID")
    }
}


extension Future: Codable {
    public func encode(to encoder: Encoder) throws {
        guard var single = encoder.singleValueContainer() as? FutureEncoder else {
            throw "need a future encoder"
        }

        try single.encode(self)
    }

    public convenience init(from decoder: Decoder) throws {
        fatalError("blah")
    }
}

extension Array: ResponseRepresentable {
    public func makeResponse(for request: Request) throws -> Response {
        let body = try Body(JSONEncoder().encode(self))
        let res = Response(body: body)
        res.mediaType = .json
        return res
    }
}

extension User: Migration {
    typealias Database = SQLiteDatabase

    static func prepare(on conn: SQLiteConnection) -> Future<Void> {
        return conn.create(User.self) { user in
            user.data("id", length: 16, isIdentifier: true)
            user.string("name")
            user.int("age")
        }
    }

    static func revert(on conn: SQLiteConnection) -> Future<Void> {
        return conn.delete(User.self)
    }
}

struct AddUsers: Migration {
    typealias Database = SQLiteDatabase
    
    static func prepare(on conn: SQLiteConnection) -> Future<Void> {
        let bob = User(name: "Bob", age: 42)
        let vapor = User(name: "Vapor", age: 3)

        return [
            bob.save(on: conn),
            vapor.save(on: conn)
        ].flatten()
    }

    static func revert(on conn: SQLiteConnection) -> Future<Void> {
        return Future(())
    }
}



