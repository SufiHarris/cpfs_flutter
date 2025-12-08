// lib/graphql/graphql_queries.dart
// GraphQL Queries and Mutations for Charity App

class GraphQLQueries {
  // ==================== LOCATION QUERIES ====================

  /// Query to list all locations
  static const String listLocations = '''
    query ListLocations(\$limit: Int, \$nextToken: String, \$filter: TableLocationFilterInput) {
      listLocations(limit: \$limit, nextToken: \$nextToken, filter: \$filter) {
        items {
          id
          name
          type
          latitude
          longitude
          description
          address
          phone
          email
          website
          cityStateZip
          services
          city
          state
          zipCode
          county
          director
          workPhone
          fax
          createdAt
          updatedAt
        }
        nextToken
      }
    }
  ''';

  /// Query to get a specific location by ID
  static const String getLocation = '''
    query GetLocation(\$id: ID!) {
      getLocation(id: \$id) {
        id
        name
        type
        latitude
        longitude
        description
        address
        phone
        email
        website
        cityStateZip
        services
        city
        state
        zipCode
        county
        director
        workPhone
        fax
        createdAt
        updatedAt
      }
    }
  ''';

  /// Query to get locations by type (uses GSI)
  static const String locationsByType = '''
    query LocationsByType(\$type: String!, \$limit: Int, \$nextToken: String) {
      locationsByType(type: \$type, limit: \$limit, nextToken: \$nextToken) {
        items {
          id
          name
          type
          latitude
          longitude
          description
          address
          phone
          email
          website
          cityStateZip
          services
          city
          state
          zipCode
          county
          director
          workPhone
          fax
        }
        nextToken
      }
    }
  ''';

  /// Mutation to create a location
  static const String createLocation = '''
    mutation CreateLocation(\$input: CreateLocationInput!) {
      createLocation(input: \$input) {
        id
        name
        type
        latitude
        longitude
        description
        address
        phone
        email
        website
        cityStateZip
        services
        city
        state
        zipCode
        county
        director
        workPhone
        fax
        createdAt
        updatedAt
      }
    }
  ''';

  /// Mutation to update a location
  static const String updateLocation = '''
    mutation UpdateLocation(\$input: UpdateLocationInput!) {
      updateLocation(input: \$input) {
        id
        name
        type
        latitude
        longitude
        description
        address
        phone
      }
    }
  ''';

  /// Mutation to delete a location
  static const String deleteLocation = '''
    mutation DeleteLocation(\$input: DeleteLocationInput!) {
      deleteLocation(input: \$input) {
        id
      }
    }
  ''';

  // ==================== CHARITY QUERIES ====================

  /// Query to list all charities
  static const String listCharitiesWithCategories = '''
    query ListCharitiesWithCategories(\$limit: Int, \$nextToken: String) {
      listCharitiesWithCategories(limit: \$limit, nextToken: \$nextToken) {
        items {
          id
          name
          mission
          email
          phone
          website
          program
          programDescription
          processLink
          product
          category
        }
        nextToken
      }
    }
  ''';

  /// Query to get a specific charity by ID
  static const String getCharitiesWithCategories = '''
    query GetCharitiesWithCategories(\$id: ID!) {
      getCharitiesWithCategories(id: \$id) {
        id
        name
        mission
        email
        phone
        website
        program
        programDescription
        processLink
        product
        category
      }
    }
  ''';

  // ==================== BOOKMARK QUERIES ====================

  /// Query to list all bookmarks
  static const String listBookmarks = '''
    query ListBookmarks(\$limit: Int, \$nextToken: String) {
      listBookmarks(limit: \$limit, nextToken: \$nextToken) {
        items {
          id
          userId
          charityName
          charityId
          category
          createdAt
        }
        nextToken
      }
    }
  ''';

  /// Mutation to create a bookmark
  static const String createBookmark = '''
    mutation CreateBookmark(\$input: CreateBookmarkInput!) {
      createBookmark(input: \$input) {
        id
        userId
        charityName
        charityId
        category
        createdAt
      }
    }
  ''';

  /// Mutation to delete a bookmark
  static const String deleteBookmark = '''
    mutation DeleteBookmark(\$input: DeleteBookmarkInput!) {
      deleteBookmark(input: \$input) {
        id
      }
    }
  ''';

  // ==================== USER QUERIES ====================

  /// Query to get a user by ID
  static const String getUser = '''
    query GetUser(\$id: ID!) {
      getUser(id: \$id) {
        id
        email
        militaryBranch
        age
        phoneNumber
        profilePicture
        address {
          street
          city
          state
          zipCode
          country
        }
      }
    }
  ''';

  /// Query to list all users
  static const String listUsers = '''
    query ListUsers(\$limit: Int, \$nextToken: String) {
      listUsers(limit: \$limit, nextToken: \$nextToken) {
        items {
          id
          email
          militaryBranch
          age
          phoneNumber
          profilePicture
        }
        nextToken
      }
    }
  ''';

  /// Mutation to create a user
  static const String createUser = '''
    mutation CreateUser(\$input: CreateUserInput!) {
      createUser(input: \$input) {
        id
        email
        militaryBranch
        age
        phoneNumber
        profilePicture
        address {
          street
          city
          state
          zipCode
          country
        }
      }
    }
  ''';

  /// Mutation to update a user
  static const String updateUser = '''
    mutation UpdateUser(\$input: UpdateUserInput!) {
      updateUser(input: \$input) {
        id
        email
        militaryBranch
        age
        phoneNumber
        profilePicture
        address {
          street
          city
          state
          zipCode
          country
        }
      }
    }
  ''';

  /// Mutation to delete a user
  static const String deleteUser = '''
    mutation DeleteUser(\$input: DeleteUserInput!) {
      deleteUser(input: \$input) {
        id
      }
    }
  ''';
}
