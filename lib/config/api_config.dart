class ApiConfig {
  // TODO: Replace with your actual API base URL
  static const String baseUrl = 'http://3.208.90.92:3000';

  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String createWorkItemEndpoint = '/workertaskui'; 
  static const String getservices = '/services';
  static const String checkCustomerEndpoint = '/customers/check';
    static const String emptask = "/workertaskui/b3b1f0ef-0a18-4583-b0bd-f8053db2d26f/2024-10-01/active";//change active to completed to get completed tasks
}
